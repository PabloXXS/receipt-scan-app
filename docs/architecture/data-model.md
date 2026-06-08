# Модель данных (Postgres + RLS)

Все таблицы имеют `created_at`, `updated_at`. Четыре зоны доступа.

## Зона A — приватные данные пользователя
RLS: доступ по `auth.uid() = user_id` (для чеков расширено правилом семьи, зона D).

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `profiles` | `id` (=auth.uid), `country_code`, `family_id` (nullable), `display_name`, `settings jsonb` | Профиль; `country_code` — мапер к фискальному провайдеру |
| `receipts` | `id`, `user_id`, `family_id` (nullable), `country_code`, `source` (qr/ocr), `status` (pending/processing/done/failed), `qr_raw`, `photo_path`, `store_id`, `purchased_at`, `total`, `currency`, `error` | «Сырой» и обработанный чек |
| `receipt_items` | `id`, `receipt_id`, `user_id`, `family_id` (nullable), `raw_name`, `product_id`, `qty`, `unit_price`, `sum` | Позиции чека |
| `loyalty_cards` | `id`, `user_id`, `chain_id`, `barcode`, `barcode_format`, `title`, `color` | Карты лояльности |

## Зона B — общий справочник
RLS: `select` для всех авторизованных; `insert/update` — только service role (воркер).

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `products` | `id`, `canonical_name`, `category_id`, `unit`, `barcode` | Канонический каталог товаров |
| `product_aliases` | `id`, `product_id`, `raw_name`, `country_code` | Сырое название → канонический товар |
| `categories` | `id`, `name`, `parent_id` | Дерево категорий |
| `stores` | `id`, `chain_id`, `name`, `address`, `geo` (lat/lng), `region`, `country_code` | Торговые точки |
| `chains` | `id`, `name`, `country_code` | Торговые сети |
| `fiscal_providers` | `country_code`, `provider_key`, `config jsonb` | Мапинг страна → стратегия воркера |

## Зона C — обезличенная карта цен
RLS: `select` для всех авторизованных; пишет только воркер. **Нет `user_id`/`family_id`.**

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `prices` | `id`, `product_id`, `store_id`, `region`, `price`, `currency`, `observed_at` | Наблюдения цен из чеков (обезличенно) |
| `price_aggregates` | `product_id`, `region`, `min_price`, `avg_price`, `max_price`, `period`, `samples` | Предрасчитанные срезы для сравнения цен |

## Зона D — семья / совместный доступ

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `families` | `id`, `name`, `owner_id`, `currency` | Семейная группа |
| `family_members` | `family_id`, `user_id`, `role` (owner/admin/member), `joined_at` | Участники; один пользователь — максимум в одной семье |
| `family_invites` | `id`, `family_id`, `code`, `invited_email`, `status` (pending/accepted/revoked), `expires_at` | Приглашения |
| `budgets` | `id`, `scope` (user/family), `owner_id`/`family_id`, `category_id` (nullable = общий), `period` (month/week), `limit_amount`, `currency` | Лимиты трат |
| `spending_view` (VIEW) | агрегат `receipt_items` × `categories` × период | Срезы «на что и сколько» |

## Правила семьи

- Один пользователь состоит максимум в одной семье.
- Чеки члена семьи видны всем участникам:
  `receipts` доступен если `user_id = auth.uid()` **ИЛИ**
  (`family_id` IS NOT NULL **И** `family_id = current_user_family_id()`).
- `current_user_family_id()` — `SECURITY DEFINER` SQL-функция, читает
  `profiles.family_id` без рекурсии RLS.
- `families`/`family_members` видны участникам; управление — только owner/admin.
- `budgets`: личные — по `owner_id`; семейные — членам семьи (чтение), изменение —
  owner/admin.

**Приватность:** зона C никогда не содержит `user_id`/`family_id`; семейные данные
на общую карту цен не влияют. Подробнее — `privacy.md`.
