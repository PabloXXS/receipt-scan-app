-- Миграция: scan — таблица receipts (зона A) + очередь pgmq + Storage-бакет + триггеры.
-- Зона доступа: A (приватные данные пользователя; RLS по auth.uid() = user_id).
-- Инвариант приватности: таблица зоны A; в зону C (prices) отсюда ничего не уходит.

-- 1. Очередь обработки чеков (pgmq). Идемпотентно при повторном прогоне.
create extension if not exists pgmq;
do $$
begin
  perform pgmq.create('receipts_processing');
exception
  when others then null; -- очередь уже существует
end;
$$;

-- 2. Таблица «сырых»/обработанных чеков.
create table if not exists public.receipts (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  family_id    uuid,
  country_code text not null,
  source       text not null check (source in ('qr', 'ocr')),
  status       text not null default 'pending'
               check (status in ('pending', 'processing', 'done', 'failed')),
  qr_raw       text,
  photo_path   text,
  store_id     uuid,                       -- FK на stores добавим в reference-цикле
  purchased_at timestamptz,
  total        numeric(12, 2),
  currency     text,
  error        text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists receipts_user_id_idx on public.receipts (user_id);
create index if not exists receipts_status_idx on public.receipts (status);

-- updated_at — переиспользуем public.set_updated_at() из 0001.
drop trigger if exists receipts_set_updated_at on public.receipts;
create trigger receipts_set_updated_at
  before update on public.receipts
  for each row execute function public.set_updated_at();

-- 3. Серверное автозаполнение user_id / country_code / family_id из профиля.
--    Клиентским значениям этих полей не доверяем — перезаписываем.
create or replace function public.receipts_fill_owner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  new.user_id := auth.uid();
  select p.country_code, p.family_id
    into new.country_code, new.family_id
    from public.profiles p
   where p.id = auth.uid();
  return new;
end;
$$;

drop trigger if exists receipts_fill_owner_trg on public.receipts;
create trigger receipts_fill_owner_trg
  before insert on public.receipts
  for each row execute function public.receipts_fill_owner();

-- 4. Постановка задачи в очередь после создания чека.
create or replace function public.receipts_enqueue()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp, pgmq
as $$
begin
  perform pgmq.send('receipts_processing', jsonb_build_object('receipt_id', new.id));
  return new;
end;
$$;

drop trigger if exists receipts_enqueue_trg on public.receipts;
create trigger receipts_enqueue_trg
  after insert on public.receipts
  for each row execute function public.receipts_enqueue();

-- Триггерные функции не должны быть доступны как RPC (PostgREST экспонирует public).
revoke execute on function public.receipts_fill_owner() from public, anon, authenticated;
revoke execute on function public.receipts_enqueue() from public, anon, authenticated;

-- 5. RLS (зона A). Семейное правило (OR family_id = current_user_family_id())
--    добавим в family-цикле — функции current_user_family_id() ещё нет.
alter table public.receipts enable row level security;

drop policy if exists "receipts_insert_own" on public.receipts;
create policy "receipts_insert_own"
  on public.receipts for insert
  with check (user_id = auth.uid());

drop policy if exists "receipts_select_own" on public.receipts;
create policy "receipts_select_own"
  on public.receipts for select
  using (user_id = auth.uid());

drop policy if exists "receipts_delete_own" on public.receipts;
create policy "receipts_delete_own"
  on public.receipts for delete
  using (user_id = auth.uid());
-- update клиенту не даём: статусы пишет воркер service-role'ом (минуя RLS).

-- 6. Storage-бакет фото чеков (приватный) + политики по префиксу {uid}/.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

drop policy if exists "receipts_storage_insert_own" on storage.objects;
create policy "receipts_storage_insert_own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "receipts_storage_select_own" on storage.objects;
create policy "receipts_storage_select_own"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "receipts_storage_delete_own" on storage.objects;
create policy "receipts_storage_delete_own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
