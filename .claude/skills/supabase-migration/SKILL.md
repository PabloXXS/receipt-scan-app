---
name: supabase-migration
description: Создаёт миграцию Supabase/Postgres для ChekiPrices с корректными RLS-политиками по зонам доступа A–D и проверкой инварианта приватности зоны C. Вызывается пользователем как /supabase-migration <название>.
argument-hint: "<migration-name> (напр. add_loyalty_cards)"
disable-model-invocation: true
---

# Миграция Supabase (ChekiPrices)

Скилл создаёт SQL-миграцию вместе с RLS-политиками и защищает инвариант приватности.
Источник истины — `docs/architecture/data-model.md` и `docs/architecture/privacy.md`
(прочитай перед началом).

## Шаг 1. Определи зону доступа таблицы
- **Зона A — приватные данные:** RLS `auth.uid() = user_id`
  (`receipts` — плюс семейное правило). Пример: `loyalty_cards`, `receipts`.
- **Зона B — общий справочник:** `select` всем `authenticated`; `insert/update` —
  только `service_role`. Пример: `products`, `stores`, `chains`.
- **Зона C — обезличенная карта цен:** `select` всем `authenticated`; запись —
  только воркер (`service_role`). Пример: `prices`, `price_aggregates`.
- **Зона D — семья:** доступ участникам через `current_user_family_id()`; управление —
  owner/admin. Пример: `families`, `family_members`, `family_invites`, `budgets`.

## Шаг 2. ⛔ Проверка инварианта зоны C (критично)
Если таблица относится к зоне C (наблюдения/агрегаты цен):
- В DDL **запрещены** колонки `user_id` и `family_id`.
- Останови генерацию и предупреди пользователя, если такие колонки запрашиваются.

## Шаг 3. Сгенерируй миграцию
- Размести SQL в каталоге миграций Supabase (`supabase/migrations/<timestamp>_<name>.sql`;
  если каталога нет — создай его и отметь, что проект ещё не инициализирован под Supabase CLI).
- Включи: `create table` (с `created_at`/`updated_at`), нужные индексы и FK.
- **Всегда** `alter table ... enable row level security;` и явные политики под зону.
- Для зоны A/D добавь политики `using`/`with check` с `auth.uid()` или
  `current_user_family_id()`; для B/C — публичный `select` и запись через `service_role`.

## Шаг 4. Согласованность и документация
- После создания миграции напомни обновить таблицу в `docs/architecture/data-model.md`
  (новая таблица/колонки, зона, политики).
- Если решение архитектурное — предложи ADR в `docs/adr/`.
- НЕ применяй миграцию к БД без явного согласия пользователя; покажи SQL для ревью.

## Шаг 5. Проверка
- Если доступен Supabase MCP / CLI — предложи `supabase db lint` или dry-run.
- Перечисли, какие RLS-политики затронуты, и какие фичи (`docs/features/*.md`) это касается.
