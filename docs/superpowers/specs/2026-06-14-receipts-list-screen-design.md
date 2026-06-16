# Дизайн: экран списка чеков (receipts list + detail + delete + пагинация)

Дата: 2026-06-14
Фича: `receipts`
Статус: утверждён, готов к плану реализации.

## Цель

Реализовать экран списка чеков и связанный экран деталей:

- Список чеков, отсортированный по новизне (`created_at desc`).
- Строка чека: миниатюра фото, название магазина, под названием — сумма чека,
  дата создания.
- Свайп строки фиксирует кнопку-мусорку (slidable) → дефолтный флоу удаления
  (диалог подтверждения) → после удаления список перезапрашивается с начала.
- Пагинация: первая загрузка 25 элементов, по скроллу подгружается следующая
  пачка по 25.
- Тап по строке → переход на экран деталей чека.

## Контекст (что уже есть)

- Таблица `receipts` (зона A) с полями `id, user_id, family_id, country_code,
  source, status, qr_raw, photo_path, store_id, purchased_at, total, currency,
  error, created_at, updated_at`. RLS — только свои чеки (`user_id = auth.uid()`),
  семейное правило ещё не добавлено. `delete` владельцу разрешён, `update` — нет.
- Таблица `receipt_items` (`id, receipt_id, raw_name, product_id, qty,
  unit_price, sum, ...`).
- Фото чеков — приватный Storage-бакет `receipts`, доступ по префиксу `{uid}/`;
  нужен signed URL для показа.
- `store_id` пока без FK; **таблицы `stores` ещё нет** — создаём в этой задаче.
- Дизайн-система: `AppScaffold, AppCard, AppListTile, AppLoader, AppEmptyState,
  AppErrorView, AppBadge, MoneyText`. `flutter_slidable ^3.0.1` уже в зависимостях.
- Эталон 3-слойной фичи и DI — `features/scan/`. Riverpod codegen (`@riverpod`).
- GoRouter: ветка `receipts` (`/receipts`) в `StatefulShellRoute.indexedStack`.
- `core/realtime/` отсутствует — realtime в этой задаче не делаем.

## Принятые решения (brainstorming)

1. **Название магазина** — создаём таблицу `stores` (зона B) сейчас + FK + join.
   При `store_id = null` (магазин ещё не распознан воркером) — фолбэк-текст.
2. **Экран деталей** — полный (шапка + позиции + фото), без realtime.
3. **Жест удаления** — slidable: свайп фиксирует кнопку-мусорку, тап → диалог.
4. **Пагинация** — range/offset по 25, сортировка `created_at desc`.
   После удаления — полный refetch с начала (а не точечное удаление из списка).
5. **Управление состоянием пагинации** — рукописный `AsyncNotifier`
   (`ReceiptsListController`) с `items + hasMore + isLoadingMore`. Без сторонних
   пакетов пагинации. Станет эталоном — фиксируется в ADR.

## Архитектура

### 1. БД — миграция `0004_stores_chains.sql` (зона B)

- `chains` (`id, name, country_code`).
- `stores` (`id, chain_id → chains, name, address, geo (lat/lng), region,
  country_code`) — по `docs/architecture/data-model.md`.
- RLS зоны B: `select` всем `authenticated`; `insert/update` — только
  service-role (воркер); клиентских политик записи нет.
- FK `receipts.store_id → stores.id` (требуется для PostgREST-эмбеда `stores(name)`).
- Инвариант приватности: `stores`/`chains` — зона B, **без** `user_id`/`family_id`.
- Миграцию обязательно прогнать через субагент `privacy-rls-reviewer`.
- Делать через скилл `/supabase-migration`.

### 2. Domain (`features/receipts/domain/`)

- `entities/receipt_status.dart` — enum `pending/processing/done/failed`
  (+ маппинг из строки БД, + тон для `AppBadge`).
- `entities/receipt.dart` (freezed) — `id, storeId?, storeName?, total?,
  currency?, status, purchasedAt?, createdAt, photoPath?`.
- `entities/receipt_item.dart` (freezed) — `id, rawName, qty, unitPrice, sum`.
- `entities/receipt_details.dart` (freezed) — `Receipt receipt` +
  `List<ReceiptItem> items`.
- `repositories/receipts_repository.dart` (abstract interface):
  - `Future<List<Receipt>> list({required int limit, required int offset})`
  - `Future<ReceiptDetails> getById(String id)`
  - `Future<void> delete(String id)`
  - `Future<String?> photoUrl(String path)` (signed URL, single)
  - (опц.) батч signed URL для страницы списка.

### 3. Data (`features/receipts/data/`)

- `models/receipt_dto.dart` — маппинг из строки PostgREST (включая эмбед
  `stores(name)`) в `Receipt`. Имя магазина = `stores.name`, при `null` — фолбэк
  на уровне presentation.
- `models/receipt_item_dto.dart`, `models/receipt_details_dto.dart`.
- `datasources/receipts_remote_datasource.dart` (поверх `SupabaseClient`):
  - `list`: `.from('receipts').select('id, total, currency, status,
    purchased_at, created_at, photo_path, store_id, stores(name)')
    .order('created_at', ascending: false).range(from, to)`.
  - `getById`: чек + `receipt_items`.
  - `delete`: `.from('receipts').delete().eq('id', id)`.
  - signed URL: `storage.from('receipts').createSignedUrl(path, ttl)` (и батч
    `createSignedUrls` на страницу).
- `repositories/receipts_repository_impl.dart` + DI-провайдеры по образцу
  `scan_repository_impl.dart`.

### 4. Presentation (`features/receipts/presentation/`)

- `controllers/receipts_list_controller.dart` (`@riverpod`):
  - Состояние (freezed) `ReceiptsListState`: `List<Receipt> items, bool hasMore,
    bool isLoadingMore`.
  - `build()` — грузит первую страницу (25), возвращает `AsyncValue` состояния.
  - `loadMore()` — следующая страница (`offset += 25`), `hasMore = page.length == 25`.
  - `refresh()` — pull-to-refresh, перезагрузка с начала.
  - `delete(id)` — удаление через репозиторий → полный refetch с начала.
- `controllers/receipt_details_controller.dart` — `receiptDetailsProvider`
  (`FutureProvider.family<ReceiptDetails, String>`).
- `screens/receipts_screen.dart` — заменяет текущую заглушку `AppEmptyState`:
  - `AppScaffold(title: 'Чеки')`.
  - `AsyncValue` → `AppLoader` / `AppErrorView(onRetry: refresh)` /
    пусто → `AppEmptyState` / `ListView.builder` в `RefreshIndicator`.
  - `ScrollController`-слушатель: при подходе к концу (~200px) → `loadMore()`.
  - В конце списка — индикатор догрузки при `isLoadingMore`.
- `widgets/receipt_list_item.dart` — композиция каталога:
  - `Slidable` (endActionPane) → `SlidableAction` мусорка (цвет `error`) →
    `AlertDialog` подтверждения (кнопки через `AppButton`, destructive) → `delete`.
  - Контент: `leading` — миниатюра (signed URL `Image.network`) или
    иконка-плейсхолдер; title — имя магазина или фолбэк; под ним — `MoneyText`
    + дата (`intl DateFormat`, локаль); `trailing` — `AppBadge` статуса.
  - Тап → `context.push('/receipts/<id>')`.
- `widgets/receipt_status_badge.dart` — мапит `ReceiptStatus` в `AppBadge.tone`.
- `screens/receipt_details_screen.dart` — шапка (магазин/сумма/дата/статус),
  фото, список позиций; состояния loading/error через каталог.

### 5. Роутинг (`core/router/`)

- `AppRoutes.receiptDetail = '/receipts/:id'`.
- `GoRoute(path: ':id', ...)` вложенный в ветку receipts; читаем
  `state.pathParameters['id']`.

## Обработка ошибок

- Сетевые/PostgREST-ошибки → `Failure` (см. `core/error/failure.dart`),
  presentation показывает `AppErrorView(onRetry)`.
- Ошибка удаления — снэкбар (`ScaffoldMessenger`), список не меняется.
- `photo_path = null` или ошибка signed URL → иконка-плейсхолдер.

## Тестирование

- Unit: маппинг `ReceiptDto` (включая эмбед `stores(name)` и `null`),
  логика `loadMore`/`hasMore`/`delete`-refetch у контроллера (мок datasource).
- Widget: `ReceiptsScreen` — состояния empty/error/loading; `ReceiptListItem` —
  отображение фолбэка имени и статуса.
- Учитывать `test/flutter_test_config.dart` (глушение google_fonts).

## Документация (по дисциплине «живой» документации)

- Обновить `docs/features/receipts.md`: list + detail + delete + пагинация
  реализованы; фолбэк имени магазина; realtime — отдельной задачей.
- Обновить `docs/architecture/data-model.md`: `stores`/`chains` созданы, FK
  `receipts.store_id` добавлен.
- Новый ADR `docs/adr/0002-receipts-pagination.md`: range/offset по 25 как
  конвенция пагинации в проекте.
- Шапки-документации во всех новых файлах кода (шаблон
  `docs/conventions/documentation.md`).

## Вне скоупа

- Realtime-подписка на статус (`receiptStatusProvider`) — отдельная задача.
- Семейные чеки (RLS-правило семьи ещё не добавлено) — показываем только свои.
- Повторная обработка чека при `failed` (открытый вопрос spec).
- Наполнение `stores`/`chains` данными (делает воркер).
- `cached_network_image` — не добавляем, используем `Image.network`.
