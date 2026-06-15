# Миграция БД: статус `review` + RPC `confirm_receipt` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить промежуточный статус `review` в `receipts.status` и RPC `confirm_receipt`, которым клиент атомарно подтверждает распознанный чек (фиксирует правки позиций, переводит `review → done`, пересчитывает `total`) — в обход запрета клиентского `UPDATE receipts`.

**Architecture:** Чистая аддитивная миграция Supabase (зона A). Меняем CHECK-ограничение статуса; добавляем `SECURITY DEFINER`-функцию `confirm_receipt(uuid, jsonb)` с явной проверкой владения (`auth.uid()`) и гейтом статуса (`= 'review'`), которая заменяет позиции, ставит `status='done'` и пересчитывает `total` из подтверждённых позиций. Это план №2 из 4.

**Tech Stack:** PostgreSQL (Supabase), pgmq (уже есть), RLS зоны A, PostgREST RPC. Верификация — через Supabase MCP (`apply_migration`/`execute_sql`) на dev-проекте CheckPrices (`yftrsgcqrzzmxbttlltz`); миграция аддитивна и идемпотентна.

**Контекст инварианта приватности:** функция и статус живут целиком в зоне A (`receipts`/`receipt_items`). В зону C (`prices`) отсюда ничего не уходит. Изменение проверяется субагентом `privacy-rls-reviewer` (Task 3) — обязательно по CLAUDE.md.

---

## Файлы

- Create: `supabase/migrations/0008_receipt_review_confirm.sql` — миграция (CHECK + RPC).
- Create: `supabase/tests/0008_confirm_receipt_test.sql` — функциональный тест (транзакция с ROLLBACK).
- Modify: `docs/architecture/data-model.md` — статус `review`, RPC `confirm_receipt`.
- Modify: `docs/architecture/data-flow.md` — шаг подтверждения через RPC.

---

### Task 1: Миграция — статус `review` + RPC `confirm_receipt`

**Files:**
- Create: `supabase/migrations/0008_receipt_review_confirm.sql`

- [ ] **Step 1: Написать миграцию**

```sql
-- Миграция: scan — статус review + RPC confirm_receipt (зона A).
-- Зона доступа: A (приватные данные; RLS по auth.uid() = user_id).
-- Инвариант приватности: зона A; в зону C (prices) отсюда ничего не уходит.
--
-- Поток статусов: pending → processing → review → done | failed.
-- Воркер (service-role) пишет позиции и ставит review; клиент подтверждает через RPC.

-- 1. Расширяем допустимые статусы значением 'review'.
alter table public.receipts drop constraint if exists receipts_status_check;
alter table public.receipts add constraint receipts_status_check
  check (status in ('pending', 'processing', 'review', 'done', 'failed'));

-- 2. RPC подтверждения чека после ревью.
--    SECURITY DEFINER: обходит запрет клиентского UPDATE receipts, но строго
--    проверяет владение через auth.uid() и гейт статуса (только review → done).
create or replace function public.confirm_receipt(
  p_receipt_id uuid,
  p_items jsonb
)
returns public.receipts
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid     uuid := auth.uid();
  v_receipt public.receipts;
  v_total   numeric(12, 2);
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- Владение + блокировка строки. RLS под SECURITY DEFINER не действует,
  -- поэтому проверяем принадлежность явно.
  select * into v_receipt
    from public.receipts
   where id = p_receipt_id and user_id = v_uid
     for update;
  if not found then
    raise exception 'receipt % not found or not owned', p_receipt_id
      using errcode = '42501';
  end if;

  -- Гейт статуса: подтверждаем только из review.
  if v_receipt.status <> 'review' then
    raise exception 'receipt % is not in review status (%)', p_receipt_id, v_receipt.status
      using errcode = '22023';
  end if;

  -- Заменяем позиции на подтверждённые пользователем.
  delete from public.receipt_items where receipt_id = p_receipt_id;
  insert into public.receipt_items
    (receipt_id, raw_name, qty, unit_price, sum)
  select
    p_receipt_id,
    it->>'raw_name',
    coalesce(nullif(it->>'qty', '')::numeric, 1),
    nullif(it->>'unit_price', '')::numeric,
    nullif(it->>'sum', '')::numeric
  from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) as it;
  -- user_id/family_id проставит триггер receipt_items_fill_owner из auth.uid().

  -- Пересчитываем итог из подтверждённых позиций (авторитетный источник).
  select coalesce(sum(sum), 0)
    into v_total
    from public.receipt_items
   where receipt_id = p_receipt_id;

  update public.receipts
     set status = 'done', total = v_total
   where id = p_receipt_id
   returning * into v_receipt;

  return v_receipt;
end;
$$;

-- RPC вызывается клиентом → доступен authenticated (в отличие от триггерных функций).
revoke execute on function public.confirm_receipt(uuid, jsonb) from public, anon;
grant execute on function public.confirm_receipt(uuid, jsonb) to authenticated;
```

- [ ] **Step 2: Применить миграцию на dev-проект (Supabase MCP)**

Использовать MCP `apply_migration`:
- project_id: `yftrsgcqrzzmxbttlltz`
- name: `0008_receipt_review_confirm`
- query: содержимое файла из Step 1.

Expected: применяется без ошибок (миграция аддитивна и идемпотентна — `drop constraint if exists`, `create or replace function`).

- [ ] **Step 3: Проверить, что объекты созданы (non-destructive, MCP execute_sql)**

```sql
-- статус-ограничение содержит review
select pg_get_constraintdef(oid)
from pg_constraint where conname = 'receipts_status_check';
-- сигнатура и права RPC
select p.proname, pg_get_function_identity_arguments(p.oid) as args, p.prosecdef
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname = 'confirm_receipt';
```

Expected: первый запрос показывает `... review ...` в определении; второй — `confirm_receipt | p_receipt_id uuid, p_items jsonb | t` (prosecdef = true).

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/0008_receipt_review_confirm.sql
git commit -m "feat(db): receipt review status and confirm_receipt RPC"
```

---

### Task 2: Функциональный тест (happy path + два отказа)

**Files:**
- Create: `supabase/tests/0008_confirm_receipt_test.sql`

Тест выполняется ОДНИМ вызовом MCP `execute_sql` в транзакции с финальным `rollback`, чтобы не оставлять данных в dev-БД. Создаёт тестового пользователя auth + профиль + чек в статусе `review` + позиции, симулирует JWT через `request.jwt.claims`, вызывает `confirm_receipt`, проверяет результат и пути отказа.

- [ ] **Step 1: Написать тест-скрипт**

```sql
-- supabase/tests/0008_confirm_receipt_test.sql
-- Запуск: MCP execute_sql целиком (содержит rollback в конце — данные не остаются).
begin;

-- Тестовый пользователь + профиль.
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-0000000000aa', 'cr-test@example.com');
insert into public.profiles (id, country_code)
values ('00000000-0000-0000-0000-0000000000aa', 'BY')
on conflict (id) do update set country_code = 'BY';

-- Симулируем авторизованного пользователя (auth.uid()).
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';

-- Чек в статусе review с «черновыми» позициями (как от воркера).
-- Вставляем через service-role-подобный путь: временно вернёмся к postgres-роли,
-- т.к. клиент чек в review не создаёт — это делает воркер.
reset role;
insert into public.receipts (id, user_id, country_code, source, status, total)
values ('00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-0000000000aa', 'BY', 'ocr', 'review', 99.99);
insert into public.receipt_items (receipt_id, user_id, raw_name, qty, unit_price, sum)
values ('00000000-0000-0000-0000-0000000000b1',
        '00000000-0000-0000-0000-0000000000aa', 'СТАРОЕ', 1, 99.99, 99.99);

-- Снова как пользователь.
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';

-- HAPPY PATH: подтверждаем с правленными позициями.
select public.confirm_receipt(
  '00000000-0000-0000-0000-0000000000b1',
  '[{"raw_name":"Молоко","qty":1,"unit_price":2.50,"sum":2.50},
    {"raw_name":"Хлеб","qty":2,"unit_price":1.25,"sum":2.50}]'::jsonb
);

-- Проверки happy path.
do $$
declare r public.receipts; n int; s numeric;
begin
  select * into r from public.receipts where id = '00000000-0000-0000-0000-0000000000b1';
  assert r.status = 'done', 'status must be done, got ' || r.status;
  assert r.total = 5.00, 'total must be 5.00 (recomputed), got ' || r.total;
  select count(*), coalesce(sum(sum),0) into n, s
    from public.receipt_items where receipt_id = '00000000-0000-0000-0000-0000000000b1';
  assert n = 2, '2 items expected, got ' || n;
  assert s = 5.00, 'items sum 5.00 expected, got ' || s;
  assert not exists (select 1 from public.receipt_items
                     where receipt_id = '00000000-0000-0000-0000-0000000000b1'
                       and raw_name = 'СТАРОЕ'), 'old item must be replaced';
end $$;

-- ОТКАЗ 1: повторное подтверждение (статус уже done, не review) → исключение.
do $$
begin
  perform public.confirm_receipt('00000000-0000-0000-0000-0000000000b1', '[]'::jsonb);
  raise exception 'TEST FAILED: expected status-gate rejection';
exception
  when sqlstate '22023' then null; -- ожидаемо: not in review
end $$;

-- ОТКАЗ 2: чужой чек (другой uid) → исключение 42501.
reset role;
insert into auth.users (id, email)
values ('00000000-0000-0000-0000-0000000000cc', 'other@example.com');
insert into public.profiles (id, country_code)
values ('00000000-0000-0000-0000-0000000000cc', 'BY') on conflict (id) do nothing;
insert into public.receipts (id, user_id, country_code, source, status)
values ('00000000-0000-0000-0000-0000000000b2',
        '00000000-0000-0000-0000-0000000000cc', 'BY', 'ocr', 'review');
set local role authenticated;
set local request.jwt.claims =
  '{"sub":"00000000-0000-0000-0000-0000000000aa","role":"authenticated"}';
do $$
begin
  perform public.confirm_receipt('00000000-0000-0000-0000-0000000000b2', '[]'::jsonb);
  raise exception 'TEST FAILED: expected ownership rejection';
exception
  when sqlstate '42501' then null; -- ожидаемо: not owned
end $$;

select 'ALL ASSERTIONS PASSED' as result;
rollback;
```

- [ ] **Step 2: Прогнать тест (MCP execute_sql, весь файл целиком)**

Передать содержимое файла в MCP `execute_sql` (project_id `yftrsgcqrzzmxbttlltz`).
Expected: в выводе строка `ALL ASSERTIONS PASSED`, ошибок нет. `rollback` в конце — тестовые данные не остаются (проверить: `select count(*) from public.receipts where id in ('...b1','...b2')` → 0).

Если падает на `set local request.jwt.claims`/`auth.uid()` — проверить, что `auth.uid()` на dev читает `request.jwt.claims->>'sub'`; при необходимости использовать `set local request.jwt.claim.sub`. НЕ ослабляй проверки владения/статуса в функции ради зелёного теста — чини тестовую обвязку.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/0008_confirm_receipt_test.sql
git commit -m "test(db): functional test for confirm_receipt (happy path + rejections)"
```

---

### Task 3: Аудит приватности и RLS (обязательно по CLAUDE.md)

**Files:** (ревью, без изменений кода — правки по итогам, если найдутся)

- [ ] **Step 1: Запустить субагент `privacy-rls-reviewer`**

Дать ему на ревью `supabase/migrations/0008_receipt_review_confirm.sql`. Проверить:
- `confirm_receipt` не читает/не пишет зону C (`prices`, `price_aggregates`) и не протаскивает `user_id`/`family_id` в обезличенную зону;
- `SECURITY DEFINER` + `set search_path = public, pg_temp` — безопасно (нет инъекции search_path);
- владение проверяется явно (`user_id = auth.uid()`), статус-гейт на месте; `grant execute` только `authenticated`, не `anon`;
- статус-ограничение согласовано с остальной схемой; нет ослабления существующих RLS зоны A.

- [ ] **Step 2: Исправить замечания (если есть) и повторить ревью**

Если субагент нашёл проблемы — внести правки в миграцию, заново применить (`apply_migration`), повторить Task 2 (функциональный тест) и ревью. Коммит правок:

```bash
git add supabase/migrations/0008_receipt_review_confirm.sql
git commit -m "fix(db): address privacy/RLS review for confirm_receipt"
```

---

### Task 4: Обновить документацию

**Files:**
- Modify: `docs/architecture/data-model.md`
- Modify: `docs/architecture/data-flow.md`

- [ ] **Step 1: Обновить data-model.md**

В строке таблицы `receipts` заменить перечисление статусов на
`status (pending/processing/review/done/failed)`. После блока про триггеры `receipts`
добавить абзац:

```markdown
> RPC `confirm_receipt(p_receipt_id uuid, p_items jsonb)` (`SECURITY DEFINER`, миграция
> `0008`) — подтверждение чека после ревью: проверяет владение (`auth.uid()`) и статус
> (`review`), заменяет `receipt_items` на подтверждённые позиции, ставит `status=done` и
> пересчитывает `total` из суммы позиций. Обходит запрет клиентского `UPDATE receipts`,
> не расширяя UPDATE-RLS. Доступен только роли `authenticated`. Зона A.
```

- [ ] **Step 2: Обновить data-flow.md**

Найти описание потока обработки чека и добавить шаг подтверждения: после того как воркер
поставил `status=review` и записал позиции, клиент получает их через Realtime, показывает
экран-ревью и вызывает `confirm_receipt` → `status=done`. (Сформулировать в стиле
существующего файла; конкретные строки — по факту содержимого `data-flow.md`.)

- [ ] **Step 3: Commit**

```bash
git add docs/architecture/data-model.md docs/architecture/data-flow.md
git commit -m "docs(db): document review status and confirm_receipt RPC"
```

---

## Self-Review (выполнено при написании плана)

- **Spec coverage:** статус `review` — Task 1 Step 1; RPC `confirm_receipt` (владение,
  статус-гейт, замена позиций, пересчёт total, грант authenticated) — Task 1; проверка —
  Task 2 (happy path + отказ по статусу + отказ по владению); приватность/RLS — Task 3;
  документация — Task 4. Покрывает раздел спеки «Изменения схемы БД».
- **Placeholder scan:** плейсхолдеров нет; единственная «по факту» формулировка — текст в
  `data-flow.md` (Task 4 Step 2), т.к. точные строки зависят от текущего содержимого файла;
  даны конкретные требования к абзацу.
- **Type/имя consistency:** имя `confirm_receipt(p_receipt_id uuid, p_items jsonb)`,
  ограничение `receipts_status_check`, статусы `pending/processing/review/done/failed`,
  коды ошибок `42501` (владение) и `22023` (статус) — едины между миграцией, тестом и
  документацией.

## Известные риски (для исполнителя)

- Тестовая обвязка зависит от того, как `auth.uid()` читает claim на dev (`request.jwt.claims`
  vs `request.jwt.claim.sub`). Если ассерты падают на null-uid — чинить обвязку теста, не
  функцию.
- Вставка в `auth.users` напрямую — упрощение для теста; вся транзакция откатывается
  (`rollback`), данные не остаются. Если на dev есть FK/триггеры на `auth.users`, которые
  мешают, — создать тестового пользователя минимально необходимыми полями.
- `confirm_receipt` с пустым `p_items` удалит все позиции и поставит `total=0` — это
  валидный сценарий «пользователь отклонил все позиции», не баг.
