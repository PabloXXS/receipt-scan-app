# ChekiPrices — структура проекта и документация (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать каркас монорепозитория ChekiPrices — дерево каталогов `app/` (Flutter) и `worker/` (PHP), систему документации `docs/**`, файлы `CLAUDE.md` всех трёх уровней и файлы-заглушки с шапками-документацией — без реальной бизнес-логики фич.

**Architecture:** Монорепо: корень = оркестрация (docs + корневой CLAUDE.md + два подпроекта). Flutter переносится из корня в `app/` (Riverpod + чистые слои, feature-first). PHP-воркер создаётся в `worker/` (Composer, PSR-4, провайдер-паттерн, очередь pgmq). Документация — источник истины для разработки через Claude Code.

**Tech Stack:** Flutter, Riverpod (codegen), GoRouter, freezed/json_serializable; Supabase (Postgres+RLS, Auth, Storage, Realtime, pgmq); PHP 8.2+ (Composer, PSR-4), Guzzle, Monolog, PHPUnit.

**Замечание о методологии (важно):** Эта итерация создаёт только структуру, документацию и заглушки — поведенческой логики нет, поэтому TDD-цикл «failing test → impl» неприменим. Вместо behavioural-тестов каждая задача завершается **структурной верификацией**: `flutter pub get`, `dart analyze`, `composer validate`, `composer dump-autoload`, проверки существования файлов. Частые коммиты сохраняются.

**Источник истины:** [docs/superpowers/specs/2026-06-08-chekiprices-architecture-design.md](docs/superpowers/specs/2026-06-08-chekiprices-architecture-design.md). При расхождении плана и спека — спек главнее.

**Решение о размещении (подтверждено пользователем):** Flutter переносится в `app/` строго по спеку (раздел 5). Корень репозитория после переноса содержит только `app/`, `worker/`, `docs/`, корневой `CLAUDE.md`, `.git`, `.gitignore`.

---

## Карта файлов (что создаём / меняем)

**Перенос (Task 1):** весь Flutter-проект из корня → `app/` (`pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `l10n.yaml`, `.metadata`, `android/`, `ios/`, `macos/`, `web/`, `windows/`, `linux/`).

**Создаём — Flutter (`app/`):**
- `app/CLAUDE.md`
- `app/lib/main.dart`, `app/lib/app.dart`
- `app/lib/core/{config,supabase,router,theme,di,error,network,realtime,utils}/*.dart`
- `app/lib/features/<feature>/{data,domain,presentation}/...` для 8 фич
- `app/lib/shared/`, `app/lib/l10n/`
- `app/test/` (зеркало `lib/`, `.gitkeep`)

**Создаём — PHP (`worker/`):**
- `worker/composer.json`, `worker/.env.example`, `worker/CLAUDE.md`, `worker/phpunit.xml.dist`, `worker/.gitignore`
- `worker/bin/worker.php`, `worker/config/providers.php`
- `worker/src/{Queue,Supabase,Pipeline,Fiscal,Ocr,Normalization,Privacy,Support}/*.php`
- `worker/tests/` (зеркало `src/`, `.gitkeep`)

**Создаём — документация (`docs/`):**
- `docs/README.md`
- `docs/architecture/{overview,data-model,data-flow,privacy}.md`
- `docs/features/{auth,scan,receipts,statistics,price-compare,loyalty-cards,family,profile}.md`
- `docs/conventions/{flutter,php-worker,documentation}.md`
- `docs/adr/0001-pgmq-queue.md`

**Создаём — корень:**
- `/CLAUDE.md`

---

## Task 1: Перенос Flutter-проекта в `app/`

**Files:**
- Move: всё содержимое Flutter-проекта из корня → `app/`
- Modify: `app/.gitignore` (пути остаются относительными — правки не требуются)

- [ ] **Step 1: Создать каталог `app/` и перенести Flutter-проект через `git mv`**

`git mv` сохраняет историю. Артефакты сборки (`build/`, `.dart_tool/`) и IDE-файлы (`.idea/`, `*.iml`) НЕ переносим — они регенерируются.

```bash
cd /Users/pablo/work/receipt-scan-app
mkdir -p app
git mv pubspec.yaml pubspec.lock analysis_options.yaml l10n.yaml .metadata app/
git mv android ios macos web windows linux app/
# .flutter-plugins-dependencies — генерируемый, удаляем (регенерируется на pub get)
rm -f .flutter-plugins-dependencies
# Артефакты и IDE-мусор удаляем из-под git-индекса, если отслеживались
rm -rf build .dart_tool
# Файл с пробелом в имени — это заметка о запуске, переносим в docs позже вручную; пока оставляем в корне
```

- [ ] **Step 2: Проверить, что Flutter-проект распознаётся в новом месте**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub get
```
Expected: `pub get` завершается успехом, создаётся `app/.dart_tool/`. Ошибок «no pubspec.yaml found» нет.

- [ ] **Step 3: Обновить корневой `.gitignore` под монорепо**

Прочитать текущий `/Users/pablo/work/receipt-scan-app/.gitignore`, затем добавить в конец блок для подпроектов (если соответствующих строк ещё нет):

```gitignore

# === Монорепо ChekiPrices ===
# Flutter (app/)
app/.dart_tool/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/build/
app/.idea/
app/*.iml

# PHP worker (worker/)
worker/vendor/
worker/.env
worker/.phpunit.result.cache
```

- [ ] **Step 4: Верификация — структура и анализатор**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && ls app/pubspec.yaml app/android app/ios && cd app && dart analyze
```
Expected: файлы существуют; `dart analyze` выводит `No issues found!` (либо отсутствие `lib/` ещё не создаёт ошибок — анализатор завершается без падения).

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add -A
git commit -m "chore: переход на монорепо — Flutter перенесён в app/"
```

---

## Task 2: Корневой `CLAUDE.md` (Уровень 1, обзор)

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Создать `/CLAUDE.md`**

Полное содержимое файла:

```markdown
# ChekiPrices — обзор для Claude Code

Мобильное приложение умного учёта покупок: сканирование QR/фото кассового чека →
разбор на товары → статистика трат, сравнение цен между магазинами, карты
лояльности, семейный учёт, обезличенная карта цен по региону.

## Стек

| Слой | Технологии |
|---|---|
| Клиент (`app/`) | Flutter, Riverpod (codegen), GoRouter, freezed/json_serializable |
| Платформа | Supabase: Postgres + RLS, Auth, Storage, Realtime, pgmq |
| Воркер (`worker/`) | PHP 8.2+ (Composer, PSR-4), демон над очередью pgmq |

## Карта репозитория

- `app/` — Flutter-клиент. Конвенции: `app/CLAUDE.md`.
- `worker/` — PHP-воркер обработки чеков. Конвенции: `worker/CLAUDE.md`.
- `docs/` — документация (источник истины). Карта: `docs/README.md`.

## Как запускать

- Клиент: `cd app && flutter pub get && flutter run`
- Воркер: `cd worker && composer install && php bin/worker.php`

## Дисциплина «живой» документации (ОБЯЗАТЕЛЬНО)

1. **Перед реализацией фичи** прочитай `docs/features/<feature>.md` и нужный
   `docs/conventions/*.md`.
2. **После изменения кода** обнови файл фичи; при изменении схемы БД —
   `docs/architecture/data-model.md`.
3. **Архитектурное решение** → новый `docs/adr/NNNN-*.md`.
4. **Каждый созданный файл кода** — с шапкой-документацией по шаблону из
   `docs/conventions/documentation.md`.

## Границы текущего этапа

Реальная бизнес-логика фич, интеграции с фискальными API и OCR-движок ещё НЕ
реализованы — в репозитории только структура, документация и заглушки. Каждая
последующая фича идёт циклом spec → plan → implementation.
```

- [ ] **Step 2: Верификация**

Run: `test -f /Users/pablo/work/receipt-scan-app/CLAUDE.md && echo OK`
Expected: `OK`

- [ ] **Step 3: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add CLAUDE.md
git commit -m "docs: корневой CLAUDE.md с обзором и дисциплиной документации"
```

---

## Task 3: Система документации — `docs/README.md` и `docs/architecture/`

**Files:**
- Create: `docs/README.md`
- Create: `docs/architecture/overview.md`
- Create: `docs/architecture/data-model.md`
- Create: `docs/architecture/data-flow.md`
- Create: `docs/architecture/privacy.md`

- [ ] **Step 1: Создать `docs/README.md`**

```markdown
# Документация ChekiPrices

Источник истины для разработки через Claude Code. Перед задачей читай
релевантные файлы (см. правило в корневом `CLAUDE.md`).

## Карта

- **architecture/** — как устроена система:
  - `overview.md` — компоненты и поток данных.
  - `data-model.md` — таблицы, поля, связи, RLS-зоны A–D.
  - `data-flow.md` — жизненный цикл чека от скана до статистики.
  - `privacy.md` — модель приватности и анонимизации цен.
- **features/** — по одному файлу на фичу (единый шаблон): `auth`, `scan`,
  `receipts`, `statistics`, `price-compare`, `loyalty-cards`, `family`,
  `profile`.
- **conventions/** — правила кодирования: `flutter.md`, `php-worker.md`,
  `documentation.md`.
- **adr/** — Architecture Decision Records: `0001-pgmq-queue.md`.
- **specs/** — дизайн-доки (выход brainstorming).
- **superpowers/plans/** — планы реализации.
```

- [ ] **Step 2: Создать `docs/architecture/overview.md`**

```markdown
# Архитектура — обзор

ChekiPrices состоит из трёх компонентов.

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

## Компоненты

- **Flutter (`app/`)** — клиент: Riverpod (codegen) + чистая слоистая
  архитектура, feature-first. Зависимости направлены внутрь:
  `presentation → domain ← data`.
- **Supabase** — Postgres с RLS, Auth (email+пароль и OAuth Google/Apple),
  Storage (фото чеков), Realtime (статус обработки), очередь `pgmq`.
- **PHP-воркер (`worker/`)** — долгоживущий демон: читает очередь, по стране
  выбирает фискального провайдера, тянет состав чека, при неудаче — OCR-fallback,
  нормализует товары, публикует обезличенные цены.

См. также `data-flow.md` (поток чека), `data-model.md` (схема), `privacy.md`
(приватность), `adr/0001-pgmq-queue.md` (почему pgmq).
```

- [ ] **Step 3: Создать `docs/architecture/data-model.md`**

````markdown
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
````

- [ ] **Step 4: Создать `docs/architecture/data-flow.md`**

```markdown
# Поток обработки чека

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
   (`product_id, store_id, region, price, currency, observed_at` — без `user_id`
   и `family_id`) в `prices` (см. `privacy.md`).
6. Flutter через **Realtime** подписан на свою строку `receipts` → видит смену
   статуса и подтягивает позиции.

## Очередь

Выбран `pgmq` (см. `adr/0001-pgmq-queue.md`): устойчивость к долгим фискальным
запросам, ретраи и visibility-timeout «из коробки», не выходя за пределы
Postgres/Supabase. `JobConsumer` в воркере: успех → `pgmq.delete`, ошибка →
инкремент попыток, исчерпание → `pgmq.archive` + `receipts.status = failed`.
```

- [ ] **Step 5: Создать `docs/architecture/privacy.md`**

```markdown
# Приватность и анонимизация

Личные траты пользователя приватны. На общую карту цен попадают только
обезличенные наблюдения.

## Зоны данных

- **Зона A** (приватная) — `receipts`, `receipt_items`, `loyalty_cards`,
  `profiles`. Доступ строго по `auth.uid()` (+ правило семьи для чеков).
- **Зона C** (обезличенная) — `prices`, `price_aggregates`. **Никогда** не
  содержит `user_id`/`family_id`. Чтение — всем авторизованным, запись — только
  воркером (service role).

## Точка анонимизации

Единственное место отрыва наблюдения цены от пользователя:
- `worker/src/Privacy/PriceAnonymizer.php` — преобразует `ReceiptData` в
  обезличенные наблюдения (отбрасывает `user_id`/`family_id`, оставляет
  `product_id, store_id, region, price, currency, observed_at`).
- `worker/src/Pipeline/Steps/PublishPricesStep.php` — записывает их в `prices`.

Изоляция в одном модуле делает приватность легко аудируемой.

## Семья

Семейные данные (`family_id`) не влияют на зону C: при публикации цен
`family_id` отбрасывается так же, как `user_id`.
```

- [ ] **Step 6: Верификация**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && ls docs/README.md docs/architecture/overview.md docs/architecture/data-model.md docs/architecture/data-flow.md docs/architecture/privacy.md
```
Expected: все пять путей выводятся без ошибок.

- [ ] **Step 7: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add docs/README.md docs/architecture/
git commit -m "docs: карта документации и раздел architecture/"
```

---

## Task 4: Документация `docs/conventions/`

**Files:**
- Create: `docs/conventions/documentation.md`
- Create: `docs/conventions/flutter.md`
- Create: `docs/conventions/php-worker.md`

- [ ] **Step 1: Создать `docs/conventions/documentation.md`**

````markdown
# Конвенции документирования

Документация — источник истины. Дисциплина и шаблоны ниже обязательны.

## Дисциплина «живой» документации

1. Перед реализацией — прочитать `docs/features/<feature>.md` и нужный
   `docs/conventions/*.md`.
2. После изменения кода — обновить файл фичи; при изменении схемы — `data-model.md`.
3. Архитектурное решение → новый `docs/adr/NNNN-*.md`.
4. Каждый созданный файл кода — с шапкой-документацией (шаблоны ниже).

## Шаблон файла фичи `docs/features/<feature>.md`

Разделы (в этом порядке):
- **Назначение**
- **Пользовательские сценарии**
- **Экраны / UI**
- **Задействованные сущности БД**
- **Репозитории и use-cases**
- **Riverpod-провайдеры**
- **Затрагиваемые RLS-политики**
- **Взаимодействие с воркером**
- **Открытые вопросы**

## Шапка файла — Dart

Файловый dartdoc-заголовок в начале файла; публичные API — с `///`.

```dart
/// Назначение: краткое описание ответственности файла.
///
/// Слой: presentation | domain | data
/// Фича: receipts
/// Зависимости: ключевые типы/провайдеры, от которых зависит файл.
/// Ключевые типы: основные экспортируемые классы/функции.
library;
```

## Шапка файла — PHP

Файловый PHPDoc-блок + PHPDoc на классы и публичные методы.

```php
<?php

declare(strict_types=1);

/**
 * Назначение: краткое описание ответственности файла.
 *
 * Роль в пайплайне: где в обработке чека участвует (если применимо).
 * Зависимости: ключевые классы/интерфейсы.
 */

namespace ChekiPrices\Worker\...;
```
````

- [ ] **Step 2: Создать `docs/conventions/flutter.md`**

```markdown
# Конвенции Flutter (`app/`)

## Архитектура

- Feature-first: `lib/features/<feature>/{data,domain,presentation}/`.
- Зависимости направлены внутрь: `presentation → domain ← data`.
  `domain` не зависит ни от `data`, ни от `presentation`.
- Общая инфраструктура — в `lib/core/`; переиспользуемый UI/DTO — в `lib/shared/`.

## Слои фичи

- `data/` — `datasources/` (Supabase/PostgREST), `models/` (DTO, freezed+json),
  `repositories/` (реализации доменных интерфейсов).
- `domain/` — `entities/` (чистые сущности), `repositories/` (абстракции),
  `usecases/` (сценарии).
- `presentation/` — `controllers/` (Riverpod-нотифаеры), `screens/`, `widgets/`.

## DI и состояние

- DI через Riverpod-провайдеры. Цепочка:
  `SupabaseClient → datasource → repository → usecase → controller`.
  Отдельных DI-пакетов нет.
- Codegen: `riverpod_generator`, `freezed`, `json_serializable`.
  Генерация: `dart run build_runner build --delete-conflicting-outputs`.

## Навигация

- `GoRouter` с `redirect` по `authStateChanges` (см. `core/router/`).

## Realtime

- В фиче `receipts` контроллер подписывается на строку чека через
  хелперы `core/realtime/`.

## Именование

- Файлы — `snake_case.dart`. Классы — `UpperCamelCase`. Провайдеры — `camelCase`.
- Тесты зеркалят `lib/` в `test/`, суффикс `_test.dart`.

## Документация файла

Каждый файл — с dartdoc-шапкой по шаблону из `documentation.md`.
```

- [ ] **Step 3: Создать `docs/conventions/php-worker.md`**

```markdown
# Конвенции PHP-воркера (`worker/`)

## Структура и автозагрузка

- PSR-4: namespace `ChekiPrices\Worker\` → `src/`.
- Точка входа — `bin/worker.php` (цикл чтения очереди pgmq).
- Тесты зеркалят `src/` в `tests/` (PHPUnit).
- PHP 8.2+: `declare(strict_types=1)` в каждом файле.

## Очередь

- `JobConsumer` читает `pgmq` с visibility-timeout: успех → `delete`,
  ошибка → инкремент попыток, исчерпание → `archive` + `receipts.status = failed`.

## Провайдер-паттерн (фискальные данные)

- `FiscalProviderInterface::fetchReceipt(QrData): ReceiptData`.
- `FiscalProviderFactory` резолвит провайдера по `country_code` (+ таблица
  `fiscal_providers`). Новая страна = новый класс в `Fiscal/Providers/` + строка
  конфига в `config/providers.php`.

## Пайплайн

- `ReceiptProcessor` оркестрирует шаги `Pipeline/Steps/*` и возвращает
  `ProcessingResult`.

## Доступ к БД и приватность

- Доступ к Supabase только через service-role ключ (`SupabaseClient`).
- Анонимизация изолирована в `Privacy/PriceAnonymizer` и `PublishPricesStep` —
  единственная точка отрыва наблюдений от пользователя (см. `architecture/privacy.md`).

## Документация файла

Каждый файл — с файловым PHPDoc-блоком и PHPDoc на классы/методы по шаблону из
`documentation.md`.
```

- [ ] **Step 4: Верификация**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && ls docs/conventions/documentation.md docs/conventions/flutter.md docs/conventions/php-worker.md
```
Expected: все три пути существуют.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add docs/conventions/
git commit -m "docs: conventions/ — документирование, Flutter, PHP-воркер"
```

---

## Task 5: ADR и файлы фич `docs/features/`

**Files:**
- Create: `docs/adr/0001-pgmq-queue.md`
- Create: `docs/features/{auth,scan,receipts,statistics,price-compare,loyalty-cards,family,profile}.md`

- [ ] **Step 1: Создать `docs/adr/0001-pgmq-queue.md`**

```markdown
# ADR-0001: Очередь обработки чеков — pgmq

- **Дата:** 2026-06-08
- **Статус:** принято

## Контекст

Обработка чека долгая и ненадёжная: запрос к фискальному провайдеру, возможный
OCR-fallback. Нужны ретраи, видимость «в обработке» и устойчивость к падению
воркера, желательно без новой инфраструктуры вне Supabase/Postgres.

## Решение

Использовать `pgmq` (расширение очередей в Postgres, поддерживается Supabase).

## Последствия

- **Плюсы:** visibility-timeout, ретраи и архивация «из коробки»; не выходим за
  пределы Postgres; триггер на `receipts` ставит задачу транзакционно.
- **Минусы:** пропускная способность ограничена Postgres; нет готового UI
  мониторинга очереди.

## Альтернативы

- Внешний брокер (RabbitMQ/SQS) — отвергнут: лишняя инфраструктура для текущего
  масштаба.
- Polling таблицы `receipts` по статусу — отвергнут: нет visibility-timeout и
  ретраев без ручной реализации.
```

- [ ] **Step 2: Создать `docs/features/auth.md`**

```markdown
# Фича: auth

## Назначение
Аутентификация: email+пароль и OAuth (Google/Apple), управление сессией.
Телефон/OTP — позже (вне текущего этапа).

## Пользовательские сценарии
- Регистрация по email+паролю с выбором страны (передаётся в профиль).
- Вход по email+паролю и через OAuth.
- Автологин по сохранённой сессии; выход.

## Экраны / UI
Sign in, Sign up, восстановление пароля.

## Задействованные сущности БД
`profiles` (создаётся при первой регистрации).

## Репозитории и use-cases
`AuthRepository` (signIn/signUp/signOut/currentSession); use-cases входа/выхода/регистрации.

## Riverpod-провайдеры
`authStateChanges` (стрим сессии Supabase), `authControllerProvider`.

## Затрагиваемые RLS-политики
Зона A: создание `profiles` по `auth.uid()`.

## Взаимодействие с воркером
Нет.

## Открытые вопросы
- Набор OAuth-провайдеров на старте.
- Политика подтверждения email.
```

- [ ] **Step 3: Создать `docs/features/scan.md`**

```markdown
# Фича: scan

## Назначение
Сканирование QR кассового чека или фотографирование чека, заливка фото в Storage
и создание «сырого» чека в `receipts`.

## Пользовательские сценарии
- Сканировать QR → создать `receipt` (`source = qr`).
- Сфотографировать чек → залить фото → создать `receipt` (`source = ocr`).

## Экраны / UI
Экран сканера (камера/QR), предпросмотр фото, индикатор отправки.

## Задействованные сущности БД
`receipts` (insert: `status = pending`, `source`, `country_code` из профиля,
`qr_raw` или `photo_path`).

## Репозитории и use-cases
`ScanRepository` (uploadPhoto, createReceipt); use-case «создать чек из скана».

## Riverpod-провайдеры
`scanControllerProvider`, провайдер доступа к камере/сканеру.

## Затрагиваемые RLS-политики
Зона A: insert `receipts` по `auth.uid()`; запись в Storage в свой префикс.

## Взаимодействие с воркером
Косвенно: insert в `receipts` → триггер ставит задачу в `pgmq`.

## Открытые вопросы
- Формат и валидация `qr_raw` по странам.
- Ограничения размера/качества фото.
```

- [ ] **Step 4: Создать `docs/features/receipts.md`**

```markdown
# Фича: receipts

## Назначение
Список и детали чеков; подписка на статус обработки в реальном времени.

## Пользовательские сценарии
- Смотреть список своих (и семейных) чеков.
- Открыть чек: видеть статус (pending/processing/done/failed) и позиции.
- Видеть смену статуса без перезагрузки (Realtime).

## Экраны / UI
Список чеков, детали чека с позициями и статусом.

## Задействованные сущности БД
`receipts`, `receipt_items`, `products` (для названий), `stores`.

## Репозитории и use-cases
`ReceiptsRepository` (list, getById, watchReceipt); use-cases списка и деталей.

## Riverpod-провайдеры
`receiptsListProvider`, `receiptDetailsProvider`, `receiptStatusProvider`
(подписка на строку через `core/realtime/`).

## Затрагиваемые RLS-политики
Зона A + правило семьи: `user_id = auth.uid()` ИЛИ `family_id = current_user_family_id()`.

## Взаимодействие с воркером
Воркер обновляет `status` и пишет `receipt_items`; клиент видит через Realtime.

## Открытые вопросы
- Поведение UI при `failed` (повтор обработки?).
```

- [ ] **Step 5: Создать `docs/features/statistics.md`**

```markdown
# Фича: statistics

## Назначение
Статистика «на что и сколько», графики и бюджеты (личные и семейные).

## Пользовательские сценарии
- Срезы трат по категориям и периодам.
- Графики динамики (fl_chart).
- Установка и отслеживание бюджетов (лимитов) по категории/периоду.

## Экраны / UI
Дашборд статистики, графики, экран бюджетов.

## Задействованные сущности БД
`spending_view` (агрегат), `receipt_items`, `categories`, `budgets`.

## Репозитории и use-cases
`StatisticsRepository` (срезы), `BudgetsRepository` (CRUD бюджетов);
use-cases агрегации и контроля лимитов.

## Riverpod-провайдеры
`spendingByCategoryProvider`, `budgetsProvider`.

## Затрагиваемые RLS-политики
Зона A + зона D (бюджеты: личные по `owner_id`, семейные — членам семьи).

## Взаимодействие с воркером
Нет (работает по уже обработанным данным).

## Открытые вопросы
- Набор предустановленных периодов; мультивалютность в семье.
```

- [ ] **Step 6: Создать `docs/features/price-compare.md`**

```markdown
# Фича: price-compare

## Назначение
Сравнение цен на товар между магазинами по региону на основе обезличенной карты цен.

## Пользовательские сценарии
- Найти товар → увидеть, где дешевле (min/avg/max по региону).
- Сравнить цены в разных магазинах/сетях.

## Экраны / UI
Поиск товара, экран сравнения цен, карточка товара с диапазоном цен.

## Задействованные сущности БД
`prices`, `price_aggregates` (зона C), `products`, `stores`, `chains`.

## Репозитории и use-cases
`PriceCompareRepository` (по продукту/региону); use-case сравнения.

## Riverpod-провайдеры
`priceComparisonProvider(productId, region)`.

## Затрагиваемые RLS-политики
Зона C: `select` всем авторизованным; запись — только воркер.

## Взаимодействие с воркером
Воркер наполняет `prices`/`price_aggregates` (анонимно).

## Открытые вопросы
- Гранулярность региона; частота пересчёта `price_aggregates`.
```

- [ ] **Step 7: Создать `docs/features/loyalty-cards.md`**

```markdown
# Фича: loyalty-cards

## Назначение
Хранение карт лояльности в приложении (без пластика), показ штрихкода на кассе.

## Пользовательские сценарии
- Добавить карту: сканировать/ввести штрихкод, выбрать сеть, задать название/цвет.
- Показать карту со штрихкодом нужного формата.
- Удалить карту.

## Экраны / UI
Список карт, добавление карты, экран показа штрихкода.

## Задействованные сущности БД
`loyalty_cards`, `chains` (привязка к сети).

## Репозитории и use-cases
`LoyaltyCardsRepository` (CRUD); use-cases добавления/удаления.

## Riverpod-провайдеры
`loyaltyCardsProvider`, `loyaltyCardControllerProvider`.

## Затрагиваемые RLS-политики
Зона A: доступ по `auth.uid() = user_id`.

## Взаимодействие с воркером
Нет.

## Открытые вопросы
- Поддерживаемые `barcode_format`.
```

- [ ] **Step 8: Создать `docs/features/family.md`**

```markdown
# Фича: family

## Назначение
Семейная группа: совместный анализ трат, приглашения, роли.

## Пользовательские сценарии
- Создать семью (владелец), пригласить участников по коду/email.
- Принять приглашение; выйти из семьи (один пользователь — максимум в одной семье).
- Видеть совместные траты и чеки участников.

## Экраны / UI
Экран семьи, список участников, приглашения, управление ролями.

## Задействованные сущности БД
`families`, `family_members`, `family_invites`, `profiles.family_id`.

## Репозитории и use-cases
`FamilyRepository` (create, invite, accept, revoke, leave, members);
use-cases управления участниками.

## Riverpod-провайдеры
`familyProvider`, `familyMembersProvider`, `familyInvitesProvider`.

## Затрагиваемые RLS-политики
Зона D: участники видят `families`/`family_members`; управление — owner/admin.
Чеки членов видны через `current_user_family_id()` (см. `data-model.md`).

## Взаимодействие с воркером
Нет напрямую. Воркер при публикации цен отбрасывает `family_id` (приватность).

## Открытые вопросы
- Срок жизни инвайта; смена владельца семьи.
```

- [ ] **Step 9: Создать `docs/features/profile.md`**

```markdown
# Фича: profile

## Назначение
Профиль пользователя: страна (мапер к фискальному провайдеру), отображаемое имя,
настройки.

## Пользовательские сценарии
- Выбрать/сменить страну (влияет на провайдера обработки чеков).
- Изменить отображаемое имя и настройки.

## Экраны / UI
Экран профиля, выбор страны, настройки.

## Задействованные сущности БД
`profiles` (`country_code`, `display_name`, `settings jsonb`, `family_id`).

## Репозитории и use-cases
`ProfileRepository` (get, update); use-case обновления профиля.

## Riverpod-провайдеры
`profileProvider`, `profileControllerProvider`.

## Затрагиваемые RLS-политики
Зона A: доступ по `auth.uid() = id`.

## Взаимодействие с воркером
Косвенно: `country_code` определяет фискального провайдера в воркере.

## Открытые вопросы
- Список поддерживаемых стран на старте (СНГ).
```

- [ ] **Step 10: Верификация**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && ls docs/adr/0001-pgmq-queue.md docs/features/auth.md docs/features/scan.md docs/features/receipts.md docs/features/statistics.md docs/features/price-compare.md docs/features/loyalty-cards.md docs/features/family.md docs/features/profile.md
```
Expected: все девять путей существуют.

- [ ] **Step 11: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add docs/adr/ docs/features/
git commit -m "docs: ADR-0001 (pgmq) и файлы 8 фич по шаблону"
```

---

## Task 6: `app/CLAUDE.md` и зависимости pubspec

**Files:**
- Create: `app/CLAUDE.md`
- Modify: `app/pubspec.yaml` (добавить `go_router`)

- [ ] **Step 1: Создать `app/CLAUDE.md`**

```markdown
# Flutter-клиент ChekiPrices (`app/`)

Конвенции этого подпроекта. Полные правила — `../docs/conventions/flutter.md`.
Перед реализацией фичи читай `../docs/features/<feature>.md`.

## Архитектура

- Feature-first: `lib/features/<feature>/{data,domain,presentation}/`.
- Зависимости внутрь: `presentation → domain ← data`. `domain` ни от чего не зависит.
- Инфраструктура — `lib/core/`; переиспользуемое — `lib/shared/`.

## DI / состояние / навигация

- DI через Riverpod-провайдеры: `SupabaseClient → datasource → repository →
  usecase → controller`.
- Codegen: `dart run build_runner build --delete-conflicting-outputs`.
- Навигация: `GoRouter` с `redirect` по `authStateChanges` (`core/router/`).
- Realtime: подписка на строку чека через `core/realtime/`.

## Команды

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart analyze`
- `flutter test`

## Документация файла

Каждый `.dart`-файл — с dartdoc-шапкой по шаблону из
`../docs/conventions/documentation.md`.
```

- [ ] **Step 2: Добавить `go_router` в `app/pubspec.yaml`**

GoRouter в спеке используется (`core/router/`), но в зависимостях отсутствует.
Найти строку `supabase_flutter: ^2.5.6` в `app/pubspec.yaml` и добавить сразу после неё:

```yaml
  go_router: ^14.2.0
```

- [ ] **Step 3: Верификация — зависимости разрешаются**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub get
```
Expected: успех, `go_router` появляется в `pubspec.lock`.

- [ ] **Step 4: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/CLAUDE.md app/pubspec.yaml app/pubspec.lock
git commit -m "docs: app/CLAUDE.md; chore: добавлен go_router"
```

---

## Task 7: Flutter `core/` — инфраструктурный каркас

**Files:**
- Create: `app/lib/core/config/app_config.dart`
- Create: `app/lib/core/config/supabase_config.dart`
- Create: `app/lib/core/supabase/supabase_providers.dart`
- Create: `app/lib/core/router/app_router.dart`
- Create: `app/lib/core/theme/app_theme.dart`
- Create: `app/lib/core/di/core_providers.dart`
- Create: `app/lib/core/error/failure.dart`
- Create: `app/lib/core/network/.gitkeep`
- Create: `app/lib/core/realtime/.gitkeep`
- Create: `app/lib/core/utils/.gitkeep`

Все файлы — валидный Dart с dartdoc-шапкой, минимальное компилируемое содержимое
(инфраструктурная проводка, не бизнес-логика фич).

- [ ] **Step 1: `app/lib/core/config/supabase_config.dart`**

```dart
/// Назначение: конфигурация подключения к Supabase (URL и anon-ключ).
///
/// Слой: core/config
/// Зависимости: значения из --dart-define окружения.
/// Ключевые типы: SupabaseConfig.
library;

/// Параметры подключения к Supabase, читаемые из окружения сборки.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  /// URL проекта Supabase (`--dart-define=SUPABASE_URL=...`).
  final String url;

  /// Публичный anon-ключ (`--dart-define=SUPABASE_ANON_KEY=...`).
  final String anonKey;

  /// Читает конфигурацию из `--dart-define` значений сборки.
  factory SupabaseConfig.fromEnv() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
}
```

- [ ] **Step 2: `app/lib/core/config/app_config.dart`**

```dart
/// Назначение: общие флаги и константы приложения.
///
/// Слой: core/config
/// Зависимости: нет.
/// Ключевые типы: AppConfig.
library;

/// Глобальные настройки приложения (нечувствительные значения).
class AppConfig {
  const AppConfig();

  /// Базовая локаль по умолчанию.
  static const String defaultLocale = 'ru';
}
```

- [ ] **Step 3: `app/lib/core/supabase/supabase_providers.dart`**

```dart
/// Назначение: предоставляет инициализированный SupabaseClient как Riverpod-провайдер.
///
/// Слой: core/supabase
/// Зависимости: supabase_flutter, flutter_riverpod.
/// Ключевые типы: supabaseClientProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Глобальный клиент Supabase (инициализируется в `main.dart`).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
```

- [ ] **Step 4: `app/lib/core/router/app_router.dart`**

```dart
/// Назначение: конфигурация навигации (GoRouter) с redirect по auth-состоянию.
///
/// Слой: core/router
/// Зависимости: go_router, flutter_riverpod.
/// Ключевые типы: appRouterProvider.
/// Заглушка: маршруты фич добавляются по мере реализации.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Провайдер корневого роутера приложения.
///
/// TODO(feature): подключить redirect по `authStateChanges` и маршруты фич.
final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  ),
);
```

- [ ] **Step 5: `app/lib/core/theme/app_theme.dart`**

```dart
/// Назначение: тема приложения (ThemeData, цвета, типографика).
///
/// Слой: core/theme
/// Зависимости: flutter material.
/// Ключевые типы: AppTheme.
library;

import 'package:flutter/material.dart';

/// Фабрики тем приложения.
class AppTheme {
  const AppTheme._();

  /// Светлая тема по умолчанию.
  static ThemeData light() => ThemeData(useMaterial3: true);
}
```

- [ ] **Step 6: `app/lib/core/di/core_providers.dart`**

```dart
/// Назначение: точка сбора корневых Riverpod-провайдеров инфраструктуры.
///
/// Слой: core/di
/// Зависимости: реэкспорт провайдеров core.
/// Ключевые типы: реэкспорт.
/// Заглушка: пополняется по мере добавления core-сервисов.
library;

export '../router/app_router.dart';
export '../supabase/supabase_providers.dart';
```

- [ ] **Step 7: `app/lib/core/error/failure.dart`**

```dart
/// Назначение: базовый тип ошибок домена и маппинг исключений.
///
/// Слой: core/error
/// Зависимости: нет.
/// Ключевые типы: Failure.
library;

/// Базовая ошибка прикладного уровня.
sealed class Failure {
  const Failure(this.message);

  /// Человекочитаемое сообщение об ошибке.
  final String message;
}

/// Непредвиденная ошибка.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}
```

- [ ] **Step 8: Заглушки пустых core-подкаталогов**

Создать пустые файлы-маркеры, чтобы каталоги попали в git:

```bash
cd /Users/pablo/work/receipt-scan-app
touch app/lib/core/network/.gitkeep app/lib/core/realtime/.gitkeep app/lib/core/utils/.gitkeep
```

- [ ] **Step 9: Верификация — анализатор**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub get && dart analyze lib/core
```
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core
git commit -m "feat(app): инфраструктурный каркас core/ (config, supabase, router, theme, di, error)"
```

---

## Task 8: Flutter `main.dart` и `app.dart` (bootstrap)

**Files:**
- Create: `app/lib/main.dart`
- Create: `app/lib/app.dart`

- [ ] **Step 1: `app/lib/app.dart`**

```dart
/// Назначение: корневой виджет — MaterialApp.router, тема, навигация.
///
/// Слой: presentation (корень)
/// Зависимости: core/router, core/theme, flutter_riverpod.
/// Ключевые типы: ChekiPricesApp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Корневой виджет приложения.
class ChekiPricesApp extends ConsumerWidget {
  const ChekiPricesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ChekiPrices',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: `app/lib/main.dart`**

```dart
/// Назначение: точка входа — инициализация Supabase и запуск ProviderScope.
///
/// Слой: bootstrap
/// Зависимости: supabase_flutter, flutter_riverpod, core/config.
/// Ключевые типы: main().
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnv();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  runApp(const ProviderScope(child: ChekiPricesApp()));
}
```

- [ ] **Step 3: Верификация — анализатор**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && dart analyze lib/main.dart lib/app.dart
```
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/main.dart app/lib/app.dart
git commit -m "feat(app): bootstrap main.dart + app.dart (Supabase.initialize, ProviderScope, router)"
```

---

## Task 9: Flutter — скелеты 8 фич, `shared/`, `l10n/`, `test/`

**Files:**
- Create: для каждой фичи `f` из {`auth`, `scan`, `receipts`, `statistics`, `price_compare`, `loyalty_cards`, `family`, `profile`} — каталоги слоёв с `.gitkeep`.
- Create: `app/lib/features/profile/...` — образцовые заглушки с шапками (по спеку).
- Create: `app/lib/shared/.gitkeep`, `app/lib/l10n/.gitkeep`, `app/test/.gitkeep`

Примечание по именованию: каталоги фич — `snake_case`, поэтому `price-compare` →
`price_compare`, `loyalty-cards` → `loyalty_cards` (соответствие файлам
`docs/features/price-compare.md` и `loyalty-cards.md`).

- [ ] **Step 1: Создать дерево слоёв всех 8 фич с маркерами**

```bash
cd /Users/pablo/work/receipt-scan-app/app/lib/features
for f in auth scan receipts statistics price_compare loyalty_cards family profile; do
  mkdir -p "$f/data/datasources" "$f/data/models" "$f/data/repositories"
  mkdir -p "$f/domain/entities" "$f/domain/repositories" "$f/domain/usecases"
  mkdir -p "$f/presentation/controllers" "$f/presentation/screens" "$f/presentation/widgets"
  find "$f" -type d -empty -exec touch {}/.gitkeep \;
done
```

- [ ] **Step 2: Образцовые заглушки для `profile/` (трёхслойный образец из спека)**

Создать `app/lib/features/profile/domain/entities/profile.dart`:

```dart
/// Назначение: доменная сущность профиля пользователя.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: нет.
/// Ключевые типы: Profile.
/// Заглушка: поля и логика добавляются в итерации фичи profile.
library;

/// Профиль пользователя (страна, имя, привязка к семье).
class Profile {
  const Profile({
    required this.id,
    required this.countryCode,
    this.displayName,
    this.familyId,
  });

  /// Идентификатор пользователя (= auth.uid).
  final String id;

  /// Код страны (мапер к фискальному провайдеру).
  final String countryCode;

  /// Отображаемое имя.
  final String? displayName;

  /// Идентификатор семьи (если состоит в семье).
  final String? familyId;
}
```

Создать `app/lib/features/profile/domain/repositories/profile_repository.dart`:

```dart
/// Назначение: абстракция доступа к данным профиля.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: domain/entities/profile.dart.
/// Ключевые типы: ProfileRepository.
/// Заглушка: реализация — в data-слое в итерации фичи profile.
library;

import '../entities/profile.dart';

/// Контракт репозитория профиля.
abstract interface class ProfileRepository {
  /// Возвращает профиль текущего пользователя.
  Future<Profile> getCurrent();

  /// Сохраняет изменённый профиль.
  Future<void> update(Profile profile);
}
```

- [ ] **Step 3: Создать маркеры `shared/`, `l10n/`, `test/`**

```bash
cd /Users/pablo/work/receipt-scan-app/app
mkdir -p lib/shared lib/l10n test
touch lib/shared/.gitkeep lib/l10n/.gitkeep test/.gitkeep
```

- [ ] **Step 4: Верификация — анализатор по всему `lib/`**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && dart analyze lib
```
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/features app/lib/shared app/lib/l10n app/test
git commit -m "feat(app): скелеты 8 фич (data/domain/presentation), образец profile, shared/l10n/test"
```

---

## Task 10: PHP-воркер — манифест, окружение, `CLAUDE.md`

**Files:**
- Create: `worker/composer.json`
- Create: `worker/.env.example`
- Create: `worker/.gitignore`
- Create: `worker/phpunit.xml.dist`
- Create: `worker/CLAUDE.md`

- [ ] **Step 1: `worker/composer.json`**

```json
{
    "name": "chekiprices/worker",
    "description": "ChekiPrices receipt-processing worker (pgmq consumer).",
    "type": "project",
    "require": {
        "php": ">=8.2",
        "guzzlehttp/guzzle": "^7.8",
        "vlucas/phpdotenv": "^5.6",
        "monolog/monolog": "^3.6"
    },
    "require-dev": {
        "phpunit/phpunit": "^11.0"
    },
    "autoload": {
        "psr-4": {
            "ChekiPrices\\Worker\\": "src/"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "ChekiPrices\\Worker\\Tests\\": "tests/"
        }
    },
    "config": {
        "sort-packages": true
    },
    "minimum-stability": "stable"
}
```

- [ ] **Step 2: `worker/.env.example`**

```dotenv
# Supabase / Postgres доступ воркера (service-role)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=
DB_DSN=pgsql:host=db.your-project.supabase.co;port=5432;dbname=postgres

# Очередь pgmq
PGMQ_QUEUE=receipts
PGMQ_VISIBILITY_TIMEOUT=60
PGMQ_MAX_ATTEMPTS=5

# Логирование
LOG_LEVEL=info
```

- [ ] **Step 3: `worker/.gitignore`**

```gitignore
/vendor/
.env
.phpunit.result.cache
```

- [ ] **Step 4: `worker/phpunit.xml.dist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         colors="true">
    <testsuites>
        <testsuite name="worker">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

- [ ] **Step 5: `worker/CLAUDE.md`**

```markdown
# PHP-воркер ChekiPrices (`worker/`)

Конвенции этого подпроекта. Полные правила — `../docs/conventions/php-worker.md`.

## Структура

- PSR-4: `ChekiPrices\Worker\` → `src/`. Тесты — `ChekiPrices\Worker\Tests\` → `tests/`.
- Точка входа: `bin/worker.php` (цикл чтения очереди pgmq).
- PHP 8.2+: `declare(strict_types=1)` в каждом файле.

## Ключевые правила

- Очередь: `JobConsumer` читает `pgmq` с visibility-timeout (успех → delete,
  ошибка → retry, исчерпание → archive + `receipts.status = failed`).
- Фискальные провайдеры: `FiscalProviderFactory` по `country_code`; новая страна =
  новый класс в `src/Fiscal/Providers/` + строка в `config/providers.php`.
- Доступ к БД — только service-role (`SupabaseClient`).
- Анонимизация — только в `Privacy/PriceAnonymizer` и `PublishPricesStep`.

## Команды

- `composer install`
- `composer validate`
- `php bin/worker.php`
- `vendor/bin/phpunit`

## Документация файла

Каждый `.php`-файл — файловый PHPDoc-блок + PHPDoc на классы/методы
(шаблон в `../docs/conventions/documentation.md`).
```

- [ ] **Step 6: Верификация — манифест валиден**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/worker && composer validate --no-check-all --strict
```
Expected: `./composer.json is valid`.

- [ ] **Step 7: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add worker/composer.json worker/.env.example worker/.gitignore worker/phpunit.xml.dist worker/CLAUDE.md
git commit -m "chore(worker): composer.json, .env.example, phpunit, CLAUDE.md"
```

---

## Task 11: PHP-воркер — точка входа, конфиг, Support, Queue

**Files:**
- Create: `worker/bin/worker.php`
- Create: `worker/config/providers.php`
- Create: `worker/src/Support/Config.php`
- Create: `worker/src/Support/Logger.php`
- Create: `worker/src/Queue/PgmqClient.php`
- Create: `worker/src/Queue/JobConsumer.php`

Все файлы — валидный PHP с `declare(strict_types=1)`, файловым PHPDoc и PHPDoc на
классы/методы. Тела методов — заглушки (`throw new \RuntimeException('Not implemented')`
или пустые), без бизнес-логики.

- [ ] **Step 1: `worker/src/Support/Config.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: доступ к конфигурации воркера из окружения (.env).
 *
 * Роль в пайплайне: инфраструктура; читается на старте bin/worker.php.
 * Зависимости: vlucas/phpdotenv (загрузка .env в bin/worker.php).
 */

namespace ChekiPrices\Worker\Support;

/**
 * Тонкая обёртка над переменными окружения воркера.
 */
final class Config
{
    /**
     * Возвращает значение переменной окружения или значение по умолчанию.
     */
    public function get(string $key, ?string $default = null): ?string
    {
        $value = $_ENV[$key] ?? getenv($key);
        return $value === false || $value === null ? $default : (string) $value;
    }
}
```

- [ ] **Step 2: `worker/src/Support/Logger.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: фабрика логгера воркера.
 *
 * Роль в пайплайне: инфраструктура наблюдаемости.
 * Зависимости: monolog/monolog.
 */

namespace ChekiPrices\Worker\Support;

use Psr\Log\LoggerInterface;

/**
 * Создаёт настроенный PSR-3 логгер.
 */
final class Logger
{
    /**
     * Создаёт логгер с заданным уровнем.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public static function create(string $level = 'info'): LoggerInterface
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 3: `worker/src/Queue/PgmqClient.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: клиент очереди pgmq (read/delete/archive).
 *
 * Роль в пайплайне: транспорт задач между Postgres-триггером и воркером.
 * Зависимости: PDO/PostgREST через SupabaseClient (внедряется позже).
 */

namespace ChekiPrices\Worker\Queue;

/**
 * Низкоуровневые операции над очередью pgmq.
 */
final class PgmqClient
{
    /**
     * Читает до $limit сообщений с visibility-timeout (секунды).
     *
     * @return array<int, array{msg_id:int, message:array<string,mixed>}>
     * @throws \RuntimeException пока не реализовано.
     */
    public function read(string $queue, int $visibilityTimeout, int $limit = 1): array
    {
        throw new \RuntimeException('Not implemented');
    }

    /**
     * Удаляет успешно обработанное сообщение.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function delete(string $queue, int $msgId): void
    {
        throw new \RuntimeException('Not implemented');
    }

    /**
     * Архивирует сообщение, исчерпавшее попытки.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function archive(string $queue, int $msgId): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 4: `worker/src/Queue/JobConsumer.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: цикл обработки очереди — read → handle → delete | retry/archive.
 *
 * Роль в пайплайне: верхнеуровневый драйвер; вызывает ReceiptProcessor.
 * Зависимости: PgmqClient, Pipeline\ReceiptProcessor.
 */

namespace ChekiPrices\Worker\Queue;

use ChekiPrices\Worker\Pipeline\ReceiptProcessor;

/**
 * Потребитель очереди pgmq: один проход цикла читает и обрабатывает задачи.
 */
final class JobConsumer
{
    public function __construct(
        private readonly PgmqClient $queue,
        private readonly ReceiptProcessor $processor,
    ) {
    }

    /**
     * Один проход: читает пачку сообщений и обрабатывает каждое.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function tick(string $queue, int $visibilityTimeout): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 5: `worker/config/providers.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: дефолтный мапинг country_code → provider_key.
 *
 * Роль в пайплайне: используется FiscalProviderFactory как фоллбэк к таблице
 * fiscal_providers.
 * Зависимости: нет.
 *
 * @return array<string, string>
 */

return [
    'RU' => 'ru_fns',
    'BY' => 'by',
    'KZ' => 'kz',
];
```

- [ ] **Step 6: `worker/bin/worker.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: точка входа воркера — загрузка окружения и цикл чтения очереди pgmq.
 *
 * Роль в пайплайне: процесс-демон; на каждом проходе вызывает JobConsumer::tick.
 * Зависимости: Composer autoload, Support\Config, Queue\JobConsumer.
 * Заглушка: реальный цикл/wiring собирается в итерации воркера.
 */

require __DIR__ . '/../vendor/autoload.php';

// TODO(worker): загрузить .env (vlucas/phpdotenv), собрать зависимости и
// запустить бесконечный цикл JobConsumer::tick().
fwrite(STDOUT, "ChekiPrices worker — скелет. Логика обработки не реализована.\n");
```

- [ ] **Step 7: Верификация — autoload и синтаксис**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/worker && composer dump-autoload 2>/dev/null; php -l bin/worker.php && php -l config/providers.php && find src -name '*.php' -exec php -l {} \;
```
Expected: для каждого файла `No syntax errors detected`.

- [ ] **Step 8: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add worker/bin worker/config worker/src/Support worker/src/Queue
git commit -m "feat(worker): точка входа, конфиг провайдеров, Support и Queue (заглушки)"
```

---

## Task 12: PHP-воркер — Supabase, Fiscal, Pipeline, прочие модули

**Files:**
- Create: `worker/src/Supabase/SupabaseClient.php`
- Create: `worker/src/Supabase/ReceiptRepository.php`
- Create: `worker/src/Supabase/CatalogRepository.php`
- Create: `worker/src/Supabase/PriceRepository.php`
- Create: `worker/src/Fiscal/FiscalProviderInterface.php`
- Create: `worker/src/Fiscal/FiscalProviderFactory.php`
- Create: `worker/src/Fiscal/Dto/QrData.php`
- Create: `worker/src/Fiscal/Dto/ItemData.php`
- Create: `worker/src/Fiscal/Dto/ReceiptData.php`
- Create: `worker/src/Fiscal/Providers/{RuFnsProvider,ByProvider,KzProvider,NullProvider}.php`
- Create: `worker/src/Pipeline/ReceiptProcessor.php`
- Create: `worker/src/Pipeline/ProcessingResult.php`
- Create: `worker/src/Pipeline/Steps/{FetchFiscalDataStep,OcrFallbackStep,NormalizeItemsStep,PersistReceiptStep,PublishPricesStep}.php`
- Create: `worker/src/Ocr/OcrEngineInterface.php`
- Create: `worker/src/Ocr/ReceiptOcrParser.php`
- Create: `worker/src/Normalization/ProductNormalizer.php`
- Create: `worker/src/Privacy/PriceAnonymizer.php`

- [ ] **Step 1: DTO — `worker/src/Fiscal/Dto/QrData.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: DTO разобранных данных QR-кода чека.
 *
 * Роль в пайплайне: вход для FiscalProviderInterface::fetchReceipt.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Сырые данные QR кассового чека.
 */
final readonly class QrData
{
    public function __construct(
        public string $raw,
        public string $countryCode,
    ) {
    }
}
```

- [ ] **Step 2: DTO — `worker/src/Fiscal/Dto/ItemData.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: DTO одной позиции чека от фискального провайдера.
 *
 * Роль в пайплайне: элемент ReceiptData; вход для нормализации.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Позиция чека (сырое название, количество, цена).
 */
final readonly class ItemData
{
    public function __construct(
        public string $rawName,
        public float $qty,
        public float $unitPrice,
        public float $sum,
    ) {
    }
}
```

- [ ] **Step 3: DTO — `worker/src/Fiscal/Dto/ReceiptData.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: DTO полного состава чека от провайдера/OCR.
 *
 * Роль в пайплайне: результат FetchFiscalDataStep/OcrFallbackStep; вход
 * нормализации, записи и анонимизации.
 * Зависимости: Dto\ItemData.
 */

namespace ChekiPrices\Worker\Fiscal\Dto;

/**
 * Состав чека: магазин, дата, итог и позиции.
 */
final readonly class ReceiptData
{
    /**
     * @param list<ItemData> $items
     */
    public function __construct(
        public ?string $storeExternalId,
        public ?string $purchasedAt,
        public ?float $total,
        public ?string $currency,
        public array $items,
    ) {
    }
}
```

- [ ] **Step 4: `worker/src/Fiscal/FiscalProviderInterface.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: контракт фискального провайдера (страна → стратегия).
 *
 * Роль в пайплайне: абстракция получения состава чека по QR.
 * Зависимости: Dto\QrData, Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Fiscal;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Стратегия получения состава чека у фискального оператора страны.
 */
interface FiscalProviderInterface
{
    /**
     * Запрашивает состав чека по данным QR.
     */
    public function fetchReceipt(QrData $qr): ReceiptData;
}
```

- [ ] **Step 5: `worker/src/Fiscal/FiscalProviderFactory.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: резолвит фискального провайдера по country_code.
 *
 * Роль в пайплайне: точка расширения «новая страна = новый класс + конфиг».
 * Зависимости: FiscalProviderInterface, config/providers.php, таблица fiscal_providers.
 */

namespace ChekiPrices\Worker\Fiscal;

/**
 * Фабрика фискальных провайдеров по коду страны.
 */
final class FiscalProviderFactory
{
    /**
     * @param array<string, string> $countryToProviderKey
     */
    public function __construct(
        private readonly array $countryToProviderKey,
    ) {
    }

    /**
     * Возвращает провайдера для указанной страны.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function forCountry(string $countryCode): FiscalProviderInterface
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 6: Провайдеры — `RuFnsProvider`, `ByProvider`, `KzProvider`, `NullProvider`**

Создать `worker/src/Fiscal/Providers/RuFnsProvider.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для России (ФНС).
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = RU.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция с API ФНС — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер ФНС РФ.
 */
final class RuFnsProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

Создать `worker/src/Fiscal/Providers/ByProvider.php` (аналогично, класс `ByProvider`, комментарий «Беларусь, country_code = BY»):

```php
<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для Беларуси.
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = BY.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер для Беларуси.
 */
final class ByProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

Создать `worker/src/Fiscal/Providers/KzProvider.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: фискальный провайдер для Казахстана.
 *
 * Роль в пайплайне: реализация FiscalProviderInterface для country_code = KZ.
 * Зависимости: FiscalProviderInterface, Dto\*.
 * Заглушка: интеграция — в отдельной итерации.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер для Казахстана.
 */
final class KzProvider implements FiscalProviderInterface
{
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

Создать `worker/src/Fiscal/Providers/NullProvider.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: провайдер-заглушка для стран без интеграции (всегда триггерит OCR-fallback).
 *
 * Роль в пайплайне: безопасный дефолт фабрики; форсирует OcrFallbackStep.
 * Зависимости: FiscalProviderInterface, Dto\*.
 */

namespace ChekiPrices\Worker\Fiscal\Providers;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderInterface;

/**
 * Провайдер по умолчанию: фискальные данные недоступны.
 */
final class NullProvider implements FiscalProviderInterface
{
    /**
     * Всегда возвращает пустой состав (сигнал к OCR-fallback).
     */
    public function fetchReceipt(QrData $qr): ReceiptData
    {
        return new ReceiptData(null, null, null, null, []);
    }
}
```

- [ ] **Step 7: `worker/src/Ocr/OcrEngineInterface.php` и `ReceiptOcrParser.php`**

`worker/src/Ocr/OcrEngineInterface.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: контракт OCR-движка (фото → текст).
 *
 * Роль в пайплайне: используется OcrFallbackStep, когда фискальные данные не получены.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Ocr;

/**
 * Абстракция OCR-движка.
 */
interface OcrEngineInterface
{
    /**
     * Распознаёт текст с фотографии чека по пути в Storage.
     */
    public function recognize(string $photoPath): string;
}
```

`worker/src/Ocr/ReceiptOcrParser.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: разбор распознанного текста чека в ReceiptData.
 *
 * Роль в пайплайне: преобразует выход OcrEngineInterface в структуру чека.
 * Зависимости: OcrEngineInterface, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Ocr;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Парсер текста чека в структурированные данные.
 */
final class ReceiptOcrParser
{
    public function __construct(
        private readonly OcrEngineInterface $engine,
    ) {
    }

    /**
     * Распознаёт и парсит фото чека в ReceiptData.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function parse(string $photoPath): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 8: `worker/src/Normalization/ProductNormalizer.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: нормализация сырого названия позиции в канонический product_id.
 *
 * Роль в пайплайне: используется NormalizeItemsStep (через product_aliases/products).
 * Зависимости: Supabase\CatalogRepository (внедряется позже).
 */

namespace ChekiPrices\Worker\Normalization;

/**
 * Сопоставляет сырые названия товаров каноническому каталогу.
 */
final class ProductNormalizer
{
    /**
     * Возвращает product_id для сырого названия в контексте страны (или null).
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function resolveProductId(string $rawName, string $countryCode): ?string
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 9: `worker/src/Privacy/PriceAnonymizer.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: преобразует состав чека в обезличенные наблюдения цен.
 *
 * Роль в пайплайне: ЕДИНСТВЕННАЯ точка отрыва наблюдений от пользователя
 * (см. ../docs/architecture/privacy.md). Отбрасывает user_id/family_id.
 * Зависимости: Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Privacy;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;

/**
 * Строит обезличенные наблюдения цен из обработанного чека.
 */
final class PriceAnonymizer
{
    /**
     * Возвращает наблюдения цен (product_id, store_id, region, price, currency,
     * observed_at) без user_id/family_id.
     *
     * @return list<array<string, mixed>>
     * @throws \RuntimeException пока не реализовано.
     */
    public function anonymize(ReceiptData $receipt, string $region): array
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 10: `worker/src/Pipeline/ProcessingResult.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: итог обработки одного чека (статус и опциональная ошибка).
 *
 * Роль в пайплайне: возвращается ReceiptProcessor в JobConsumer.
 * Зависимости: нет.
 */

namespace ChekiPrices\Worker\Pipeline;

/**
 * Результат прохода пайплайна по чеку.
 */
final readonly class ProcessingResult
{
    public function __construct(
        public string $status,
        public ?string $error = null,
    ) {
    }
}
```

- [ ] **Step 11: Шаги пайплайна `worker/src/Pipeline/Steps/*`**

`FetchFiscalDataStep.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: шаг — выбрать провайдера по стране и запросить состав чека.
 *
 * Роль в пайплайне: шаг 1 ReceiptProcessor.
 * Зависимости: Fiscal\FiscalProviderFactory, Fiscal\Dto\*.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\QrData;
use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Fiscal\FiscalProviderFactory;

/**
 * Получение фискальных данных чека.
 */
final class FetchFiscalDataStep
{
    public function __construct(
        private readonly FiscalProviderFactory $factory,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(QrData $qr): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`OcrFallbackStep.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: шаг — OCR-fallback, если фискальные данные не получены.
 *
 * Роль в пайплайне: шаг 2 (условный) ReceiptProcessor.
 * Зависимости: Ocr\ReceiptOcrParser, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Ocr\ReceiptOcrParser;

/**
 * OCR-распознавание чека по фото как запасной путь.
 */
final class OcrFallbackStep
{
    public function __construct(
        private readonly ReceiptOcrParser $parser,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(string $photoPath): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`NormalizeItemsStep.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: шаг — нормализовать сырые названия позиций в product_id.
 *
 * Роль в пайплайне: шаг 3 ReceiptProcessor.
 * Зависимости: Normalization\ProductNormalizer, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Normalization\ProductNormalizer;

/**
 * Нормализация позиций чека.
 */
final class NormalizeItemsStep
{
    public function __construct(
        private readonly ProductNormalizer $normalizer,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(ReceiptData $receipt, string $countryCode): ReceiptData
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`PersistReceiptStep.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: шаг — записать receipt_items и обновить статус чека.
 *
 * Роль в пайплайне: шаг 4 ReceiptProcessor.
 * Зависимости: Supabase\ReceiptRepository, Fiscal\Dto\ReceiptData.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Supabase\ReceiptRepository;

/**
 * Сохранение позиций чека и финального статуса.
 */
final class PersistReceiptStep
{
    public function __construct(
        private readonly ReceiptRepository $receipts,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(string $receiptId, ReceiptData $receipt): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`PublishPricesStep.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: шаг — опубликовать ОБЕЗЛИЧЕННЫЕ наблюдения цен.
 *
 * Роль в пайплайне: шаг 5 ReceiptProcessor; работает только с зоной C.
 * Зависимости: Privacy\PriceAnonymizer, Supabase\PriceRepository.
 */

namespace ChekiPrices\Worker\Pipeline\Steps;

use ChekiPrices\Worker\Fiscal\Dto\ReceiptData;
use ChekiPrices\Worker\Privacy\PriceAnonymizer;
use ChekiPrices\Worker\Supabase\PriceRepository;

/**
 * Публикация обезличенных цен в карту цен (зона C).
 */
final class PublishPricesStep
{
    public function __construct(
        private readonly PriceAnonymizer $anonymizer,
        private readonly PriceRepository $prices,
    ) {
    }

    /**
     * @throws \RuntimeException пока не реализовано.
     */
    public function run(ReceiptData $receipt, string $region): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 12: `worker/src/Pipeline/ReceiptProcessor.php`**

```php
<?php

declare(strict_types=1);

/**
 * Назначение: оркестратор шагов обработки одного чека.
 *
 * Роль в пайплайне: вызывается JobConsumer; последовательно прогоняет шаги
 * Fetch → (Ocr fallback) → Normalize → Persist → PublishPrices.
 * Зависимости: Pipeline\Steps\*, Pipeline\ProcessingResult.
 */

namespace ChekiPrices\Worker\Pipeline;

use ChekiPrices\Worker\Pipeline\Steps\FetchFiscalDataStep;
use ChekiPrices\Worker\Pipeline\Steps\NormalizeItemsStep;
use ChekiPrices\Worker\Pipeline\Steps\OcrFallbackStep;
use ChekiPrices\Worker\Pipeline\Steps\PersistReceiptStep;
use ChekiPrices\Worker\Pipeline\Steps\PublishPricesStep;

/**
 * Оркестратор обработки чека.
 */
final class ReceiptProcessor
{
    public function __construct(
        private readonly FetchFiscalDataStep $fetch,
        private readonly OcrFallbackStep $ocrFallback,
        private readonly NormalizeItemsStep $normalize,
        private readonly PersistReceiptStep $persist,
        private readonly PublishPricesStep $publishPrices,
    ) {
    }

    /**
     * Обрабатывает чек по его идентификатору.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function process(string $receiptId): ProcessingResult
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 13: Supabase-репозитории**

`worker/src/Supabase/SupabaseClient.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: PostgREST-клиент поверх service-role ключа.
 *
 * Роль в пайплайне: единственный канал доступа воркера к БД (зоны A/B/C).
 * Зависимости: guzzlehttp/guzzle, Support\Config.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Низкоуровневый клиент Supabase (service role).
 */
final class SupabaseClient
{
    public function __construct(
        private readonly string $url,
        private readonly string $serviceRoleKey,
    ) {
    }

    /**
     * Выполняет запрос к PostgREST.
     *
     * @param array<string, mixed> $options
     * @return array<int|string, mixed>
     * @throws \RuntimeException пока не реализовано.
     */
    public function request(string $method, string $path, array $options = []): array
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`worker/src/Supabase/ReceiptRepository.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: чтение receipts и запись receipt_items/статуса.
 *
 * Роль в пайплайне: используется PersistReceiptStep и JobConsumer.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий чеков (зона A).
 */
final class ReceiptRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Помечает статус чека.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function setStatus(string $receiptId, string $status, ?string $error = null): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`worker/src/Supabase/CatalogRepository.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: доступ к справочнику products/aliases/stores/chains.
 *
 * Роль в пайплайне: используется нормализацией и привязкой магазина.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий общего справочника (зона B).
 */
final class CatalogRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Ищет product_id по сырому названию и стране.
     *
     * @throws \RuntimeException пока не реализовано.
     */
    public function findProductIdByAlias(string $rawName, string $countryCode): ?string
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

`worker/src/Supabase/PriceRepository.php`:

```php
<?php

declare(strict_types=1);

/**
 * Назначение: запись обезличенных цен и агрегатов (зона C).
 *
 * Роль в пайплайне: используется PublishPricesStep.
 * Зависимости: SupabaseClient.
 */

namespace ChekiPrices\Worker\Supabase;

/**
 * Репозиторий карты цен (зона C, без user_id/family_id).
 */
final class PriceRepository
{
    public function __construct(
        private readonly SupabaseClient $client,
    ) {
    }

    /**
     * Вставляет обезличенные наблюдения цен.
     *
     * @param list<array<string, mixed>> $observations
     * @throws \RuntimeException пока не реализовано.
     */
    public function insertObservations(array $observations): void
    {
        throw new \RuntimeException('Not implemented');
    }
}
```

- [ ] **Step 14: Верификация — синтаксис всех PHP-файлов**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/worker && find src -name '*.php' -exec php -l {} \;
```
Expected: для каждого файла `No syntax errors detected`.

- [ ] **Step 15: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add worker/src
git commit -m "feat(worker): Supabase, Fiscal, Ocr, Normalization, Privacy, Pipeline (заглушки с PHPDoc)"
```

---

## Task 13: PHP-воркер — каталог тестов и финальная верификация репозитория

**Files:**
- Create: `worker/tests/.gitkeep`
- Verify: весь репозиторий

- [ ] **Step 1: Создать каркас каталога тестов**

```bash
cd /Users/pablo/work/receipt-scan-app/worker
mkdir -p tests
touch tests/.gitkeep
```

- [ ] **Step 2: Проверить полноту дерева каталогов**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && find app/lib worker/src worker/bin worker/config docs -type d | sort
```
Expected: присутствуют все каталоги из спека — `app/lib/core/*`, `app/lib/features/<8 фич>/{data,domain,presentation}/*`, `worker/src/{Queue,Supabase,Pipeline,Pipeline/Steps,Fiscal,Fiscal/Dto,Fiscal/Providers,Ocr,Normalization,Privacy,Support}`, `docs/{architecture,features,conventions,adr,specs}`.

- [ ] **Step 3: Финальная верификация — Flutter и PHP**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub get && dart analyze
cd /Users/pablo/work/receipt-scan-app/worker && composer validate --no-check-all --strict && find src bin config -name '*.php' -exec php -l {} \;
```
Expected: `dart analyze` → `No issues found!`; `composer.json is valid`; все PHP-файлы → `No syntax errors detected`.

- [ ] **Step 4: Проверить наличие всех CLAUDE.md и ключевых документов**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app && ls CLAUDE.md app/CLAUDE.md worker/CLAUDE.md docs/README.md docs/architecture/data-model.md docs/conventions/documentation.md docs/adr/0001-pgmq-queue.md && ls docs/features/*.md | wc -l
```
Expected: все пути существуют; `docs/features/*.md` = `8`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add worker/tests
git commit -m "chore(worker): каркас каталога tests/; завершение скелета монорепо"
```

---

## Self-Review (выполнено при составлении плана)

**1. Покрытие спека:**
- §2 Компоненты → docs/architecture/overview.md (Task 3).
- §3 Поток чека → docs/architecture/data-flow.md (Task 3).
- §4 Модель данных (зоны A–D, правила семьи) → docs/architecture/data-model.md (Task 3).
- §5 Структура Flutter → Tasks 1, 6–9 (перенос, core, bootstrap, фичи, shared/l10n/test).
- §6 Структура воркера → Tasks 10–13 (composer, bin, config, src/*, tests).
- §7 Документация (3 уровня) → CLAUDE.md ×3 (Tasks 2, 6, 10), docs/** (Tasks 3–5), шапки файлов (Tasks 7–9, 11–12), шаблоны в documentation.md.
- §8 Стек → закреплён в pubspec (Task 6) и composer.json (Task 10).
- §9 Границы итерации → все тела методов — заглушки; реальной логики нет.

**2. Заглушки-плейсхолдеры:** в плане TODO присутствуют только внутри содержимого
файлов-заглушек как намеренные маркеры будущей логики (это и есть продукт
итерации), а не как пропуски в шагах плана. Каждый шаг содержит полный контент.

**3. Согласованность типов/имён:** namespace `ChekiPrices\Worker\` единообразен;
DTO `QrData`/`ItemData`/`ReceiptData`, интерфейс `FiscalProviderInterface` и его
реализации согласованы между фабрикой, шагами и провайдерами; имена каталогов фич
в `snake_case` (`price_compare`, `loyalty_cards`) сопоставлены с файлами доков
`price-compare.md`/`loyalty-cards.md` (отмечено в Task 9).
