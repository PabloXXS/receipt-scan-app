-- Миграция: scan — таблица receipt_items (зона A) + валюта чека из страны.
-- Зона доступа: A. Инвариант приватности: зона A; в зону C (prices) ничего не уходит.

create table if not exists public.receipt_items (
  id          uuid primary key default gen_random_uuid(),
  receipt_id  uuid not null references public.receipts (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  family_id   uuid,
  raw_name    text not null,
  product_id  uuid,                 -- FK на products добавим в reference-цикле
  qty         numeric(12, 3) not null default 1,
  unit_price  numeric(12, 2),
  sum         numeric(12, 2),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists receipt_items_receipt_id_idx on public.receipt_items (receipt_id);
create index if not exists receipt_items_user_id_idx on public.receipt_items (user_id);

-- updated_at — переиспользуем public.set_updated_at() из 0001.
drop trigger if exists receipt_items_set_updated_at on public.receipt_items;
create trigger receipt_items_set_updated_at
  before update on public.receipt_items
  for each row execute function public.set_updated_at();

-- Автозаполнение владельца (как в receipts).
create or replace function public.receipt_items_fill_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  new.user_id := auth.uid();
  select p.family_id into new.family_id from public.profiles p where p.id = auth.uid();
  return new;
end; $$;

drop trigger if exists receipt_items_fill_owner_trg on public.receipt_items;
create trigger receipt_items_fill_owner_trg before insert on public.receipt_items
  for each row execute function public.receipt_items_fill_owner();

revoke execute on function public.receipt_items_fill_owner() from public, anon, authenticated;

alter table public.receipt_items enable row level security;

drop policy if exists "receipt_items_select_own" on public.receipt_items;
create policy "receipt_items_select_own" on public.receipt_items for select
  using (user_id = auth.uid());

drop policy if exists "receipt_items_insert_own" on public.receipt_items;
create policy "receipt_items_insert_own" on public.receipt_items for insert
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.receipts r
                where r.id = receipt_id and r.user_id = auth.uid())
  );

drop policy if exists "receipt_items_delete_own" on public.receipt_items;
create policy "receipt_items_delete_own" on public.receipt_items for delete
  using (user_id = auth.uid());

-- Дополняем receipts_fill_owner: валюта из country_code, если не задана клиентом.
create or replace function public.receipts_fill_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  new.user_id := auth.uid();
  select p.country_code, p.family_id into new.country_code, new.family_id
    from public.profiles p where p.id = auth.uid();
  new.currency := coalesce(new.currency, case new.country_code
    when 'BY' then 'BYN' when 'RU' then 'RUB' when 'KZ' then 'KZT' else null end);
  return new;
end; $$;

revoke execute on function public.receipts_fill_owner() from public, anon, authenticated;
