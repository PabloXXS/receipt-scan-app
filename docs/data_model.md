# Модель данных (Supabase)

## Общие поля

- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `is_deleted boolean not null default false`

## Таблицы

### users (Supabase Auth)

- Используем `auth.users` как источник истины

### merchants (legacy, не используется)

- `id uuid pk default gen_random_uuid()`
- `name text not null`
- `inn text null`
- `icon_name text default 'folder'`
- - общие поля

**Примечание**: таблица `merchants` больше не используется в приложении. Названия магазинов теперь хранятся напрямую в поле `merchant_name` таблицы `receipts`.

### receipts

- `id uuid pk default gen_random_uuid()`
- `user_id uuid not null` (fk -> auth.users)
- `merchant_name text null` -- название магазина из OCR (не FK)
- `purchase_date date null`
- `purchase_time time null`
- `total numeric(12,2) not null default 0`
- `currency text not null default 'RUB'`
- `status text not null default 'processing'` -- processing|ready|failed
- `source_file_id uuid null` (fk -> files)
- `error_text text null`
- `store_confidence numeric(3,2) null` -- уверенность в определении названия магазина (0-1)
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

### categories (категории товаров)

- `id uuid pk default gen_random_uuid()`
- `name text unique not null` -- название категории товара
- `parent_id uuid null` (self fk) -- для иерархии категорий (опционально)
- - общие поля

**Примечание**: таблица используется для группировки позиций чеков (`receipt_items`) по категориям. При анализе чека ИИ автоматически присваивает категории товарам на основе существующих категорий или может быть создана новая категория.

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
