-- Миграция: reference — справочник торговых сетей и точек (зона B) + FK на receipts.
-- Зона доступа: B (общий справочник). RLS: select всем authenticated; insert/update — service-role (воркер).
-- Инвариант приватности: зона B, БЕЗ user_id/family_id (в зону C ничего не уходит).

create table if not exists public.chains (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  country_code text not null,
  created_at   timestamptz not null default now()
);

create table if not exists public.stores (
  id           uuid primary key default gen_random_uuid(),
  chain_id     uuid references public.chains (id) on delete set null,
  name         text not null,
  address      text,
  lat          double precision,
  lng          double precision,
  region       text,
  country_code text not null,
  created_at   timestamptz not null default now()
);

create index if not exists stores_chain_id_idx on public.stores (chain_id);
create index if not exists stores_country_code_idx on public.stores (country_code);

-- FK receipts.store_id → stores.id (создавался без FK в 0002). on delete set null:
-- удаление точки справочника не должно удалять чеки пользователя.
alter table public.receipts
  drop constraint if exists receipts_store_id_fkey;
alter table public.receipts
  add constraint receipts_store_id_fkey
  foreign key (store_id) references public.stores (id) on delete set null;

-- RLS зоны B: чтение всем авторизованным; запись — только service-role (минует RLS),
-- клиентских политик insert/update/delete НЕ создаём.
alter table public.chains enable row level security;
alter table public.stores enable row level security;

drop policy if exists "chains_select_all_auth" on public.chains;
create policy "chains_select_all_auth"
  on public.chains for select to authenticated using (true);

drop policy if exists "stores_select_all_auth" on public.stores;
create policy "stores_select_all_auth"
  on public.stores for select to authenticated using (true);
