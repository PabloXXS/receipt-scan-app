-- Migration copy of docs/sql/0001_init.sql
-- Apply via Supabase CLI: supabase db reset --use-migra

-- Инициализация схемы базы данных для анализа чеков
alter default privileges revoke execute on functions from public;

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  parent_id uuid references categories(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists merchants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  inn text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists files (
  id uuid primary key default gen_random_uuid(),
  bucket text not null,
  path text not null,
  mime text,
  size bigint,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false,
  unique(bucket, path)
);

create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  merchant_name text, -- Название магазина из OCR (не FK)
  purchase_date date,
  purchase_time time,
  total numeric(12,2) not null default 0,
  currency text not null default 'RUB',
  status text not null default 'processing' 
    check (status in ('processing', 'ready', 'failed')),
  source_file_id uuid references files(id),
  error_text text,
  store_confidence numeric(3,2), -- Уверенность в определении названия магазина (0-1)
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create table if not exists receipt_items (
  id uuid primary key default gen_random_uuid(),
  receipt_id uuid not null references receipts(id) on delete cascade,
  name text not null,
  qty numeric(10,3) not null default 1,
  price numeric(12,2) not null default 0,
  sum numeric(12,2) generated always as (qty * price) stored,
  category_id uuid references categories(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

create index if not exists idx_receipts_user_id on receipts(user_id);
create index if not exists idx_receipts_status on receipts(status);
create index if not exists idx_receipts_purchase_date on receipts(purchase_date);
create index if not exists idx_receipt_items_receipt_id on receipt_items(receipt_id);
create index if not exists idx_receipt_items_name on receipt_items(name);

create table if not exists processing_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  receipt_id uuid not null,
  file_id uuid not null,
  status text not null default 'queued',
  attempts int not null default 0,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_jobs_status on processing_jobs(status);

create table if not exists usage_daily_quota (
  user_id uuid not null,
  day date not null,
  analyze_count int not null default 0,
  primary key(user_id, day)
);

create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger update_categories_updated_at 
  before update on categories 
  for each row execute procedure update_updated_at_column();

create trigger update_merchants_updated_at 
  before update on merchants 
  for each row execute procedure update_updated_at_column();

create trigger update_files_updated_at 
  before update on files 
  for each row execute procedure update_updated_at_column();

create trigger update_receipts_updated_at 
  before update on receipts 
  for each row execute procedure update_updated_at_column();

create trigger update_receipt_items_updated_at 
  before update on receipt_items 
  for each row execute procedure update_updated_at_column();

alter table categories enable row level security;
alter table merchants enable row level security;
alter table files enable row level security;
alter table receipts enable row level security;
alter table receipt_items enable row level security;

create policy "Users can view all categories" on categories
  for select using (true);

create policy "Users can view all merchants" on merchants
  for select using (true);

drop policy if exists "Users can manage their files" on files;
create policy "Users can manage their files" on files
  for all to authenticated
  using (
    exists (
      select 1 from storage.objects o
      where o.bucket_id = files.bucket
        and o.name = files.path
        and split_part(o.name, '/', 1) = auth.uid()::text
    )
  )
  with check (
    exists (
      select 1 from storage.objects o
      where o.bucket_id = files.bucket
        and o.name = files.path
        and split_part(o.name, '/', 1) = auth.uid()::text
    )
  );

drop policy if exists "Users can manage their receipts" on receipts;
create policy "Users can manage their receipts" on receipts
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can manage their receipt items" on receipt_items;
create policy "Users can manage their receipt items" on receipt_items
  for all to authenticated
  using (
    exists(
      select 1 from receipts 
      where receipts.id = receipt_items.receipt_id 
      and receipts.user_id = auth.uid()
    )
  )
  with check (
    exists(
      select 1 from receipts 
      where receipts.id = receipt_items.receipt_id 
      and receipts.user_id = auth.uid()
    )
  );

insert into categories (name) values 
  ('Продукты'),
  ('Напитки'),
  ('Хлебобулочные изделия'),
  ('Молочные продукты'),
  ('Мясо и рыба'),
  ('Овощи и фрукты'),
  ('Бытовая химия'),
  ('Косметика'),
  ('Лекарства'),
  ('Прочее')
on conflict (name) do nothing;

-- Ensure bucket exists
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

-- Storage policies for private bucket 'receipts'
drop policy if exists storage_insert_receipts on storage.objects;
create policy storage_insert_receipts on storage.objects
for insert to authenticated
with check (
  bucket_id = 'receipts'
  and split_part(name, '/', 1) = auth.uid()::text
);

drop policy if exists storage_select_receipts on storage.objects;
create policy storage_select_receipts on storage.objects
for select to authenticated
using (
  bucket_id = 'receipts'
  and split_part(name, '/', 1) = auth.uid()::text
);


