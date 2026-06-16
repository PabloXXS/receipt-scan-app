# Дизайн: сканирование чека (клиент + БД-фундамент)

- **Дата:** 2026-06-09
- **Фича:** `scan`
- **Статус:** утверждён (brainstorming)
- **Связанные доки:** [features/scan.md](../../features/scan.md),
  [architecture/data-model.md](../../architecture/data-model.md),
  [architecture/data-flow.md](../../architecture/data-flow.md),
  [architecture/privacy.md](../../architecture/privacy.md),
  [adr/0001-pgmq-queue.md](../../adr/0001-pgmq-queue.md)

## 1. Цель и границы

Реализовать **первый сквозной срез** сканирования чека: пользователь фотографирует
чек (камера или галерея), фото грузится в Storage, в таблицу `receipts` вставляется
«сырой» чек со `status = pending`, а триггер кладёт задачу в очередь `pgmq`.

### Входит в цикл
- БД-фундамент: расширение/очередь `pgmq`, таблица `receipts` (зона A), RLS,
  Storage-бакет `receipts` с политиками, триггеры автозаполнения и постановки в очередь.
- Flutter-клиент фичи `scan`: захват фото (камера + галерея) с предпросмотром,
  сжатие, загрузка, создание чека.

### НЕ входит (отдельные циклы)
- **QR-сканирование камерой** — `mobile_scanner` отключён (GoogleMLKit не собирается
  под arm64-симулятор, см. память проекта). Архитектура закладывается под QR
  (`enum ScanSource { qr, ocr }`, поле `qr_raw`, задел метода в репозитории), но сам
  скан QR — позже, с тестом на устройстве/Rosetta.
- **PHP-воркер** (чтение pgmq, фискальные API/OCR, `receipt_items`, анонимизация цен,
  смена статуса) — отдельный цикл; локально не запускается (нет PHP-runtime).
- **Просмотр чеков и Realtime** (фича `receipts`) — отдельный цикл. Без воркера чек
  остаётся `pending`.

### Сознательные сужения (technical debt, помечено)
1. **Семейное RLS-правило отложено.** `receipts` доступен только по `user_id = auth.uid()`.
   Правило `OR family_id = current_user_family_id()` добавится в family-цикле (функции
   `current_user_family_id()` ещё нет). При вставке `family_id` всё равно заполняется
   из профиля — данные совместимы наперёд.
2. **Без FK `store_id → stores`.** Таблица `stores` (зона B) ещё не создана; `store_id`
   в `receipts` — обычный `uuid`. FK добавит воркер/reference-цикл.
3. **Колонки воркера создаются сразу** (`store_id`, `purchased_at`, `total`, `currency`,
   `error`), чтобы воркер-цикл не делал `alter table`.

## 2. Подход

Вставка чека — **прямой insert из клиента** в `receipts` (паттерн как в `auth`:
`presentation → usecase → repository → datasource → SupabaseClient`). RLS + триггеры
закрывают безопасность и серверное автозаполнение. Edge Function не используется (YAGNI).

## 3. БД-фундамент — миграция `supabase/migrations/0002_receipts_scan.sql`

Зона доступа: **A** (приватные данные пользователя). Инвариант приватности: таблица
зоны A; в зону C (`prices`) из этой миграции ничего не уходит.

### 3.1 Очередь
```sql
create extension if not exists pgmq;
select pgmq.create('receipts_processing');
```

### 3.2 Таблица `receipts`
Поля по data-model:
`id` (uuid pk, `gen_random_uuid()`), `user_id` (uuid not null → `auth.users`),
`family_id` (uuid null), `country_code` (text not null),
`source` (text not null, check `in ('qr','ocr')`),
`status` (text not null default `'pending'`, check `in ('pending','processing','done','failed')`),
`qr_raw` (text null), `photo_path` (text null),
`store_id` (uuid null — без FK), `purchased_at` (timestamptz null),
`total` (numeric(12,2) null), `currency` (text null), `error` (text null),
`created_at`/`updated_at` (timestamptz not null default `now()`).

`updated_at`-триггер переиспользует `public.set_updated_at()` из `0001`.

### 3.3 Триггер `BEFORE INSERT` — серверное автозаполнение
`SECURITY DEFINER`, `set search_path = public, pg_temp`. Логика:
- `new.user_id := auth.uid();`
- `country_code` и `family_id` берём из `public.profiles where id = auth.uid()`
  (клиентским значениям этих полей не доверяем — перезаписываем).

Клиент шлёт только `source`, `photo_path`/`qr_raw`. `EXECUTE` на функции отзываем у
`public/anon/authenticated` (как `set_updated_at`/`handle_new_user` в `0001`).

### 3.4 RLS на `receipts`
`enable row level security`. Политики:
- `receipts_insert_own` — `for insert with check (user_id = auth.uid())`.
- `receipts_select_own` — `for select using (user_id = auth.uid())`.
  _(Семейное правило добавится позже — см. сужение №1.)_
- `receipts_delete_own` — `for delete using (user_id = auth.uid())`.
- `update` клиенту не даём (статусы пишет воркер service-role'ом, минуя RLS).

### 3.5 Storage-бакет `receipts` (приватный)
Создать приватный бакет `receipts`. Политики на `storage.objects` (bucket_id = 'receipts'):
пользователь делает `insert/select/delete` только когда первый сегмент пути равен его
`auth.uid()` (`(storage.foldername(name))[1] = auth.uid()::text`).
Схема пути: `{user_id}/{receipt_id}.jpg`.

### 3.6 Триггер `AFTER INSERT` — постановка в очередь
`SECURITY DEFINER`, `set search_path`. Тело:
`perform pgmq.send('receipts_processing', jsonb_build_object('receipt_id', new.id));`
`EXECUTE` отзываем у клиентских ролей.

### 3.7 Ревью
Миграция затрагивает схему `receipts` → обязательный прогон субагентом
**`privacy-rls-reviewer`** перед коммитом.

## 4. Flutter-клиент — фича `scan`

### 4.1 Поток состояний (контроллер)
`idle` → выбор источника (камера/галерея) → `preview(file)` (перенять/отправить) →
`uploading` → `success(receiptId)` / `failure`. Предпросмотр — состояние внутри
экрана-вкладки `/scan`, **без нового маршрута**.

### 4.2 Слой `domain/`
- `entities/scan_source.dart` — `enum ScanSource { qr, ocr }`.
- `repositories/scan_repository.dart` — контракт:
  `Future<String> createReceiptFromPhoto(File photo)` (возвращает id чека).
  Задел `createReceiptFromQr(String raw)` — TODO-комментарий, без реализации.
- `usecases/create_receipt_from_photo.dart` — оркестрация: сжать → загрузить → insert.

### 4.3 Слой `data/`
- `image_compressor.dart` — ресайз (длинная сторона ≤ 1600px) + JPEG q≈85 (пакет `image`).
  Закрывает открытый вопрос дока об ограничении размера/качества фото.
- `datasources/scan_remote_datasource.dart` — Storage upload (`{uid}/{receiptId}.jpg`) +
  insert в `receipts` (`source = 'ocr'`, `photo_path`), возврат id.
- `repositories/scan_repository_impl.dart` + `scan_error_mapper.dart` — маппинг
  `StorageException`/`PostgrestException`/сетевых ошибок → `ScanFailure`.

### 4.4 Слой `presentation/`
- `controllers/scan_controller.dart` — `@riverpod` `AsyncNotifier`; методы
  `pickFromCamera/pickFromGallery/retake/submit/reset`. В `build` — без сайд-эффектов.
- `screens/scan_screen.dart` — переключает захват/превью/загрузку по состоянию.
- `widgets/` — кнопки захвата, превью фото, оверлей отправки.
- UI **только** из каталога `shared/components` (`AppScaffold`, `AppButton`, `AppLoader`,
  `AppErrorView` и т.д.); прямой Material запрещён конвенцией.

### 4.5 `core/error`
Добавить sealed-семейство `ScanFailure` (`CameraPermissionDeniedFailure`,
`UploadFailure`, `ScanNetworkFailure`, `UnknownScanFailure`). Текущий `NetworkFailure`
зашит под `AuthFailure` — в scan не переиспользуем, заводим отдельный тип.

### 4.6 DI
`supabaseClientProvider → scanRemoteDataSourceProvider → scanRepositoryProvider →
createReceiptFromPhotoProvider → scanControllerProvider`.

### 4.7 iOS
Добавить в `app/ios/Runner/Info.plist`: `NSCameraUsageDescription`,
`NSPhotoLibraryUsageDescription` (иначе image_picker падает на устройстве).

## 5. Обработка ошибок
- Нет разрешения камеры/галереи → `CameraPermissionDeniedFailure` → `AppErrorView`
  с подсказкой открыть настройки.
- Сбой загрузки в Storage → `UploadFailure` (фото осталось локально, можно повторить).
- Сбой insert после успешной загрузки → `UploadFailure`; осиротевший объект Storage
  допустим на этом этапе (чистку оставляем воркеру/будущему циклу — помечено).
- Нет сети → `ScanNetworkFailure`.

## 6. Тестирование (TDD — тесты до кода)
- **usecase**: порядок `compress → upload → insert`; проброс/маппинг ошибок.
- **repository**: маппинг `StorageException`/`PostgrestException` → `ScanFailure`.
- **controller**: переходы состояний (idle → preview → uploading → success/failure).
- **widget**: захват → превью → лоадер → успех; экран ошибки при `failure`.
- Supabase мокается на границе datasource/repository (фейки), без реального бэкенда.

## 7. Документация по итогу
- Обновить [features/scan.md](../../features/scan.md): закрыть открытые вопросы
  (размер фото; QR — отдельный цикл).
- Обновить [architecture/data-model.md](../../architecture/data-model.md) при отклонениях
  от описанной схемы (FK `store_id` отложен).
- ADR — при необходимости (например, решение «без FK store_id сейчас»).
- Каждый новый `.dart`/`.sql`-файл — с шапкой-документацией по шаблону.
