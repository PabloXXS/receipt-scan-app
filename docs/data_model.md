# Модель данных (Supabase)

## Общие поля

- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `is_deleted boolean not null default false`

## Таблицы

### users (Supabase Auth)

- Используем `auth.users` как источник истины

### merchants

- `id uuid pk default gen_random_uuid()`
- `name text not null`
- `inn text null` -- при необходимости
- - общие поля

### receipts

- `id uuid pk default gen_random_uuid()`
- `user_id uuid not null` (fk -> auth.users)
- `merchant_id uuid null` (fk -> merchants)
- `purchase_date date null`
- `purchase_time time null`
- `total numeric(12,2) not null default 0`
- `currency text not null default 'RUB'`
- `status text not null default 'processing'` -- processing|ready|failed
- `source_file_id uuid null` (fk -> files)
- `error_text text null`
- - общие поля
- Индексы: `(user_id)`, `(status)`, `(purchase_date)`

### receipt_items

- `id uuid pk default gen_random_uuid()`
- `receipt_id uuid not null` (fk -> receipts)
- `name text not null`
- `qty numeric(10,3) not null default 1`
- `price numeric(12,2) not null default 0`
- `sum numeric(12,2) generated always as (qty * price) stored`
- `category_id uuid null` (fk -> categories)
- - общие поля
- Индексы: `(receipt_id)`, `(name)`

### categories

- `id uuid pk default gen_random_uuid()`
- `name text unique not null`
- `parent_id uuid null` (self fk)
- - общие поля

### files

- `id uuid pk default gen_random_uuid()`
- `bucket text not null`
- `path text not null`
- `mime text null`
- `size int8 null`
- - общие поля
- Уникальность: `(bucket, path)`

## RLS (эскиз)

- Все таблицы: политика доступа по `user_id = auth.uid()` (где применимо)
- `files`: приватный бакет, выдача подписанных URL по требованию
