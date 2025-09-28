-- Инициализация схемы базы данных для анализа чеков
-- Использовать в Supabase SQL Editor

-- Включаем RLS для всех таблиц
alter default privileges revoke execute on functions from public;

-- Таблица категорий товаров
create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  parent_id uuid references categories(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- Таблица магазинов/торговых точек
create table if not exists merchants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  inn text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- Таблица файлов (изображения чеков)
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

-- Таблица чеков
create table if not exists receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  merchant_id uuid references merchants(id),
  purchase_date date,
  purchase_time time,
  total numeric(12,2) not null default 0,
  currency text not null default 'RUB',
  status text not null default 'processing' 
    check (status in ('processing', 'ready', 'failed')),
  source_file_id uuid references files(id),
  error_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  is_deleted boolean not null default false
);

-- Таблица позиций чека
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

-- Индексы для производительности
create index if not exists idx_receipts_user_id on receipts(user_id);
create index if not exists idx_receipts_status on receipts(status);
create index if not exists idx_receipts_purchase_date on receipts(purchase_date);
create index if not exists idx_receipt_items_receipt_id on receipt_items(receipt_id);
create index if not exists idx_receipt_items_name on receipt_items(name);

-- Триггеры для updated_at
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

-- RLS политики
alter table categories enable row level security;
alter table merchants enable row level security;
alter table files enable row level security;
alter table receipts enable row level security;
alter table receipt_items enable row level security;

-- Политики доступа
create policy "Users can view all categories" on categories
  for select using (true);

create policy "Users can view all merchants" on merchants
  for select using (true);

create policy "Users can manage their files" on files
  for all using (true); -- TODO: более строгие правила

create policy "Users can manage their receipts" on receipts
  for all using (auth.uid() = user_id);

create policy "Users can manage their receipt items" on receipt_items
  for all using (
    exists(
      select 1 from receipts 
      where receipts.id = receipt_items.receipt_id 
      and receipts.user_id = auth.uid()
    )
  );

-- Начальные данные категорий
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
