# ChekiPrices — базовая архитектура (дизайн-документ)

- **Дата:** 2026-06-08
- **Статус:** утверждён (brainstorming)
- **Объём итерации:** только структура проекта + документация, без реальной бизнес-логики фич.

## 1. Продукт

Мобильное приложение для умного учёта покупок. Пользователь сканирует QR-код
кассового чека (или фотографирует чек), приложение раскладывает его на товары,
группирует траты по магазинам и показывает статистику «на что и сколько».

Главные фичи:
- **Сравнение цен между магазинами** — приложение знает, где товар дешевле.
- **Карты лояльности** в одном месте (без пластика).
- **Семья** — совместный анализ трат нескольких пользователей.
- **Карта цен по региону** — личные траты остаются приватными, а обезличенные
  цены складываются в общую карту, которой пользуются все.

## 2. Компоненты системы

```
┌─────────────┐      ┌──────────────────────────┐      ┌──────────────┐
│   Flutter    │      │         Supabase          │      │  PHP Worker   │
│  (Riverpod,  │◄────►│  Postgres + RLS + Auth +  │◄────►│  (демон,      │
│ clean layers)│      │  Storage + Realtime +     │      │  очередь pgmq)│
└─────────────┘      │  pgmq                     │      └──────┬───────┘
                      └──────────────────────────┘             │
                                                      ┌─────────▼─────────┐
                                                      │ Фискальные провайд.│
                                                      │ (страна→стратегия) │
                                                      │  + OCR fallback    │
                                                      └────────────────────┘
```

- **Flutter** — клиент, Riverpod (codegen) + чистая слоистая архитектура,
  feature-first структура.
- **Supabase** — Postgres с RLS, Auth (email+пароль и OAuth Google/Apple),
  Storage (фото чеков), Realtime (обновление статуса), очередь `pgmq`.
- **PHP-воркер** — долгоживущий демон: читает очередь, обращается к фискальным
  провайдерам по стране, делает OCR-fallback, нормализует товары, публикует
  обезличенные цены.

## 3. Поток обработки чека

1. Пользователь сканирует QR (или делает фото) → Flutter заливает фото в Storage
   и вставляет «сырой» чек в `receipts` (`status = pending`, `source = qr|ocr`,
   `country_code` из профиля).
2. Триггер на `receipts` кладёт сообщение `{receipt_id}` в очередь `pgmq`.
3. Воркер читает сообщение (`pgmq.read` с visibility-timeout), по `country_code`
   выбирает фискального провайдера, тянет состав чека; при неудаче — OCR-fallback
   по фото.
4. Воркер нормализует товары (сырое название → канонический `products` через
   `product_aliases`), пишет `receipt_items`, ставит `receipts.status = done|failed`.
5. **Анонимизация:** воркер кладёт обезличенные наблюдения цен
   (`product_id, store_id, region, price, currency, observed_at` — **без `user_id`
   и `family_id`**) в `prices`.
6. Flutter через **Realtime** подписан на свою строку `receipts` → видит смену
   статуса и подтягивает позиции.

**Решение по очереди:** выбран `pgmq` (см. ADR-0001) ради устойчивости к долгим
фискальным запросам, ретраев и visibility-timeout «из коробки», не выходя за
пределы Postgres/Supabase.

## 4. Модель данных (Postgres + RLS)

Все таблицы имеют `created_at`, `updated_at`. Четыре зоны доступа.

### Зона A — приватные данные пользователя
RLS: доступ по `auth.uid() = user_id` (для чеков — расширено правилом семьи, см. зону D).

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `profiles` | `id` (=auth.uid), `country_code`, `family_id` (nullable), `display_name`, `settings jsonb` | Профиль; `country_code` — мапер к фискальному провайдеру |
| `receipts` | `id`, `user_id`, `family_id` (nullable), `country_code`, `source` (qr/ocr), `status` (pending/processing/done/failed), `qr_raw`, `photo_path`, `store_id`, `purchased_at`, `total`, `currency`, `error` | «Сырой» и обработанный чек |
| `receipt_items` | `id`, `receipt_id`, `user_id`, `family_id` (nullable), `raw_name`, `product_id`, `qty`, `unit_price`, `sum` | Позиции чека |
| `loyalty_cards` | `id`, `user_id`, `chain_id`, `barcode`, `barcode_format`, `title`, `color` | Карты лояльности |

### Зона B — общий справочник
RLS: `select` для всех авторизованных; `insert/update` — только service role (воркер).

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `products` | `id`, `canonical_name`, `category_id`, `unit`, `barcode` | Канонический каталог товаров |
| `product_aliases` | `id`, `product_id`, `raw_name`, `country_code` | Сырое название → канонический товар |
| `categories` | `id`, `name`, `parent_id` | Дерево категорий |
| `stores` | `id`, `chain_id`, `name`, `address`, `geo` (lat/lng), `region`, `country_code` | Торговые точки |
| `chains` | `id`, `name`, `country_code` | Торговые сети |
| `fiscal_providers` | `country_code`, `provider_key`, `config jsonb` | Мапинг страна → стратегия воркера |

### Зона C — обезличенная карта цен
RLS: `select` для всех авторизованных; пишет только воркер. **Нет `user_id`/`family_id`.**

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `prices` | `id`, `product_id`, `store_id`, `region`, `price`, `currency`, `observed_at` | Наблюдения цен из чеков (обезличенно) |
| `price_aggregates` | `product_id`, `region`, `min_price`, `avg_price`, `max_price`, `period`, `samples` | Предрасчитанные срезы для сравнения цен |

### Зона D — семья / совместный доступ

| Таблица | Ключевые поля | Назначение |
|---|---|---|
| `families` | `id`, `name`, `owner_id`, `currency` | Семейная группа |
| `family_members` | `family_id`, `user_id`, `role` (owner/admin/member), `joined_at` | Участники; один пользователь — максимум в одной семье |
| `family_invites` | `id`, `family_id`, `code`, `invited_email`, `status` (pending/accepted/revoked), `expires_at` | Приглашения |
| `budgets` | `id`, `scope` (user/family), `owner_id`/`family_id`, `category_id` (nullable = общий), `period` (month/week), `limit_amount`, `currency` | Лимиты трат |
| `spending_view` (VIEW) | агрегат `receipt_items` × `categories` × период | Срезы «на что и сколько» для статистики и бюджетов |

**Правила семьи:**
- Один пользователь состоит максимум в одной семье.
- Чеки члена семьи видны всем участникам (без выборочности по каждому чеку):
  `receipts` доступен если `user_id = auth.uid()` **ИЛИ**
  (`family_id` IS NOT NULL **И** `family_id = current_user_family_id()`).
- `current_user_family_id()` — `SECURITY DEFINER` SQL-функция, читает
  `profiles.family_id` без рекурсии RLS.
- `families`/`family_members` видны участникам; управление — только owner/admin.
- `budgets`: личные — по `owner_id`; семейные — членам семьи (чтение), изменение —
  owner/admin.

**Приватность:** зона C никогда не содержит `user_id`/`family_id`; семейные данные
на общую карту цен не влияют.

## 5. Структура Flutter (`app/`)

Riverpod (codegen) + чистые слои, feature-first. Зависимости направлены внутрь:
`presentation → domain ← data`.

```
app/
├── pubspec.yaml
├── lib/
│   ├── main.dart                      # bootstrap: Supabase.initialize, ProviderScope
│   ├── app.dart                       # MaterialApp.router, тема, локализация
│   ├── core/
│   │   ├── config/                    # env, SupabaseConfig, флаги
│   │   ├── supabase/                  # клиент, провайдер SupabaseClient
│   │   ├── router/                    # GoRouter, redirect по auth-состоянию
│   │   ├── theme/                     # ThemeData, цвета, типографика
│   │   ├── di/                        # корневые Riverpod-провайдеры
│   │   ├── error/                     # Failure, маппинг ошибок
│   │   ├── network/                   # обёртки запросов, retry, маппинг PostgREST
│   │   ├── realtime/                  # хелперы Supabase Realtime
│   │   └── utils/                     # форматтеры, расширения
│   ├── features/
│   │   ├── auth/                      # email+пароль, OAuth, сессия
│   │   ├── scan/                      # QR + фото, заливка в Storage, создание receipt
│   │   ├── receipts/                  # список/детали, подписка на статус
│   │   ├── statistics/               # статистика, графики, бюджеты
│   │   ├── price_compare/            # сравнение цен по магазинам
│   │   ├── loyalty_cards/            # карты лояльности
│   │   ├── family/                   # семья, приглашения, общий анализ
│   │   └── profile/                  # профиль, выбор страны, настройки
│   │       ├── data/{datasources,models,repositories}/
│   │       ├── domain/{entities,repositories,usecases}/
│   │       └── presentation/{controllers,screens,widgets}/
│   ├── shared/                        # переиспользуемые виджеты, общие DTO
│   └── l10n/                          # локализация (ru + базовый en)
└── test/                              # зеркалит lib/
```

Каждая фича повторяет трёхслойную структуру `data/domain/presentation`,
показанную для `profile/`.

**Ключевые решения:**
- DI через Riverpod-провайдеры (`SupabaseClient → datasource → repository →
  usecase → controller`), отдельных DI-пакетов нет.
- GoRouter с `redirect` по `authStateChanges`.
- Realtime в фиче `receipts`: контроллер подписывается на строку чека.
- Codegen: `riverpod_generator`, `freezed`/`json_serializable`.

## 6. Структура PHP-воркера (`worker/`)

Долгоживущий демон (systemd/Supervisor либо по расписанию). Composer, PSR-4.

```
worker/
├── composer.json
├── .env.example                       # SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, DB_DSN, очередь
├── bin/worker.php                     # точка входа: цикл чтения очереди pgmq
├── config/providers.php               # дефолтный мапинг country_code → provider_key
├── src/
│   ├── Queue/
│   │   ├── PgmqClient.php              # read/delete/archive pgmq
│   │   └── JobConsumer.php             # цикл: read → handle → delete | retry/archive
│   ├── Supabase/
│   │   ├── SupabaseClient.php          # PostgREST поверх service-role
│   │   ├── ReceiptRepository.php       # чтение receipts, запись items/status
│   │   ├── CatalogRepository.php       # products, aliases, stores, chains
│   │   └── PriceRepository.php         # запись prices / price_aggregates
│   ├── Pipeline/
│   │   ├── ReceiptProcessor.php        # оркестратор шагов
│   │   ├── Steps/
│   │   │   ├── FetchFiscalDataStep.php # провайдер по country, запрос состава
│   │   │   ├── OcrFallbackStep.php     # fallback, если фискальные данные не получены
│   │   │   ├── NormalizeItemsStep.php  # сырое название → product
│   │   │   ├── PersistReceiptStep.php  # запись receipt_items + статус
│   │   │   └── PublishPricesStep.php   # АНОНИМИЗАЦИЯ → prices
│   │   └── ProcessingResult.php
│   ├── Fiscal/
│   │   ├── FiscalProviderInterface.php # fetchReceipt(QrData): ReceiptData
│   │   ├── FiscalProviderFactory.php   # country_code → провайдер
│   │   ├── Dto/                        # QrData, ReceiptData, ItemData
│   │   └── Providers/{RuFnsProvider,ByProvider,KzProvider,NullProvider}.php
│   ├── Ocr/{OcrEngineInterface,ReceiptOcrParser}.php
│   ├── Normalization/ProductNormalizer.php
│   ├── Privacy/PriceAnonymizer.php     # ReceiptData → обезличенные наблюдения
│   └── Support/{Logger,Config}.php
└── tests/                             # PHPUnit, зеркалит src/
```

**Ключевые решения:**
- `JobConsumer` читает `pgmq` с visibility-timeout; успех → `delete`, ошибка →
  инкремент попыток, исчерпание → `archive` + `receipts.status = failed`.
- `FiscalProviderFactory` резолвит провайдера по `country_code` (+ таблица
  `fiscal_providers`). Новая страна = новый класс + строка конфига.
- Анонимизация изолирована в `Privacy/PriceAnonymizer` и `PublishPricesStep` —
  единственное место отрыва наблюдений от пользователя; легко аудировать.
- Доступ к БД только через service-role ключ.

## 7. Система документации (разработка через Claude Code)

Весь код пишется при помощи Claude Code, поэтому документация — источник истины,
к которому Claude обращается перед каждой задачей.

**Уровень 1 — `CLAUDE.md` (читается автоматически):**
- `/CLAUDE.md` — обзор продукта, стек, карта репозитория, как запускать, ссылки
  на доки и правило «перед реализацией фичи прочитай `docs/features/<feature>.md`».
- `/app/CLAUDE.md` — конвенции Flutter (слои, зависимости, Riverpod, именование, тесты).
- `/worker/CLAUDE.md` — конвенции PHP (PSR-4, провайдер-паттерн, очередь, service-role).

**Уровень 2 — `docs/`:**

```
docs/
├── README.md                   # карта документации
├── architecture/
│   ├── overview.md             # компоненты и поток данных
│   ├── data-model.md           # таблицы, поля, связи, RLS-зоны A–D
│   ├── data-flow.md            # жизненный цикл чека
│   └── privacy.md              # модель приватности и анонимизации
├── features/                   # по одному файлу на фичу (единый шаблон)
│   ├── auth.md  scan.md  receipts.md  statistics.md
│   ├── price-compare.md  loyalty-cards.md  family.md  profile.md
├── conventions/
│   ├── flutter.md
│   ├── php-worker.md
│   └── documentation.md        # шаблоны документирования файлов и фич
├── adr/
│   └── 0001-pgmq-queue.md
└── specs/                      # дизайн-доки (выход brainstorming)
```

**Уровень 3 — документация на уровне файла (обязательна):**
- **Dart:** файловый dartdoc-заголовок (назначение, слой+фича, зависимости,
  ключевые типы); публичные API — с `///`.
- **PHP:** файловый PHPDoc-блок + PHPDoc на классы/методы (назначение, роль в
  пайплайне, зависимости).

**Шаблон файла фичи `docs/features/<feature>.md`:**
> Назначение · Пользовательские сценарии · Экраны/UI · Задействованные сущности БД ·
> Репозитории и use-cases · Riverpod-провайдеры · Затрагиваемые RLS-политики ·
> Взаимодействие с воркером · Открытые вопросы.

**Дисциплина «живой» документации (правило в `CLAUDE.md`):**
1. Перед реализацией — прочитать `docs/features/<feature>.md` и нужный `conventions/*.md`.
2. После изменения кода — обновить файл фичи и, при изменении схемы, `data-model.md`.
3. Архитектурное решение → новый `adr/NNNN-*.md`.
4. Каждый созданный файл кода — с шапкой-документацией по шаблону из `documentation.md`.

## 8. Технологический стек (зафиксировано)

| Слой | Выбор |
|---|---|
| Клиент | Flutter, Riverpod (codegen), GoRouter, freezed/json_serializable |
| Бэкенд-платформа | Supabase: Postgres + RLS, Auth, Storage, Realtime, pgmq |
| Аутентификация | Email+пароль, OAuth Google/Apple (телефон/OTP — позже) |
| Воркер | PHP (Composer, PSR-4), демон над очередью pgmq |
| Регион | Мульти-регион СНГ; страна выбирается при регистрации, мапится на провайдера |
| Очередь | pgmq (ADR-0001) |

## 9. Границы итерации (что НЕ делаем сейчас)

- Реальная бизнес-логика фич, интеграции с конкретными фискальными API, OCR-движок.
- Телефон/OTP-аутентификация.
- CI/CD, деплой воркера, инфраструктура.

Итерация создаёт: дерево каталогов `app/`, `worker/`, `docs/`, файлы `CLAUDE.md`,
наполненную документацию (`docs/**`) и файлы-заглушки с шапками-документацией, где
это уместно. Реальный код фич — последующими итерациями, каждая со своим
spec → plan → implementation.
