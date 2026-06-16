# Дизайн: загрузка фото чека при скане (photo_path)

Дата: 2026-06-14
Фича: scan (затрагивает отображение в receipts)
Статус: утверждён, готов к плану реализации.

## Проблема

При скане (галерея/живая камера) фото распознаётся OCR, но **не сохраняется**:
`SupabaseScanRemoteDataSource.insertReceiptWithItems` не загружает изображение в
Storage и не пишет `receipts.photo_path`. Доменный `ReceiptDraft` не несёт байты —
после `recognizePhoto(bytes)` они отбрасываются. Поэтому у чека `photo_path = null`,
и экран чеков (корректно) показывает плейсхолдер вместо фото.

Цель: при сохранении скана загружать снятое/выбранное фото в приватный бакет
`receipts` и проставлять `photo_path`, чтобы список и детали показывали изображение.

## Контекст (что уже есть)

- Бакет `receipts` (приватный) создан миграцией `0002` с RLS по префиксу `{uid}/`
  (insert/select/delete для владельца). **Миграция не нужна.**
- `receipts` НЕ имеет клиентской политики `UPDATE` (статусы пишет воркер
  service-role). ⇒ `photo_path` нельзя проставить после вставки — только в `insert`,
  значит загрузка фото должна предшествовать insert.
- Зависимость `package:image: ^4.2.0` уже есть; пример обработки —
  `core/images/avatar_image_processor.dart` (но он делает квадратный центр-кроп —
  для чеков не подходит, нужен даунскейл с сохранением пропорций).
- Приём загрузки в Storage — как в `profile_remote_datasource.uploadAvatar`:
  `storage.from(bucket).uploadBinary(path, bytes, FileOptions(contentType:'image/jpeg'))`.
- Байты приходят в `ScanController.recognizePhoto(Uint8List)` (галерея через
  `pickFromGallery`, живая камера через `LiveCameraScreen`). Сейчас отбрасываются.
- Отображение фото в receipts уже готово: `ReceiptPhotoThumbnail` +
  `receiptPhotoUrlProvider` (signed URL) + плейсхолдер при `null`.

## Принятые решения (brainstorming)

1. **Сжатие:** перед загрузкой кодируем в JPEG (даунскейл по большей стороне,
   q≈80) — меньше трафик/хранение, единый формат.
2. **Ошибка загрузки — best-effort:** если сжатие/загрузка упали, чек всё равно
   сохраняется с `photo_path = null` (данные чека важнее картинки).
3. **Подход A:** байты держим в приватном поле `ScanController`, репозиторий
   оркеструет process → upload → insert. Состояния `ScanState` не меняем.

## Архитектура

### 1. Обработка изображения (core)
- Новый `lib/core/images/receipt_image_processor.dart`:
  `Uint8List processReceiptPhoto(Uint8List input)` — `img.decodeImage`; если null →
  `FormatException`; даунскейл по большей стороне до `kReceiptPhotoMaxSide` (1600)
  c сохранением пропорций (если больше); `img.encodeJpg(quality: 80)`.
- Чистая функция, юнит-тестируется отдельно.

### 2. Domain (scan)
- `ScanRepository.saveScannedReceipt(ReceiptDraft draft, {Uint8List? photoBytes})`
  — добавлен опциональный `photoBytes`.
- `SaveScannedReceipt` usecase: `call(ReceiptDraft draft, {Uint8List? photoBytes})`
  → пробрасывает в репозиторий.

### 3. Data (scan)
- `ScanRemoteDataSource`:
  - новый `Future<String> uploadPhoto(Uint8List jpegBytes)` — путь
    `{uid}/{millisSinceEpoch}.jpg` (uid из `_client.auth.currentUser`), `uploadBinary`
    с `contentType: 'image/jpeg'`; возвращает путь объекта.
  - `insertReceiptWithItems(ReceiptDraft draft, {String? photoPath})` — добавляет
    `'photo_path': photoPath` в map insert.
- `ScanRepositoryImpl.saveScannedReceipt(draft, {photoBytes})`:
  1. `String? photoPath;`
  2. если `photoBytes != null`: `try { final jpeg = processReceiptPhoto(photoBytes);
     photoPath = await _ds.uploadPhoto(jpeg); } catch (_) { photoPath = null; }`
     (best-effort — сжатие или загрузка).
  3. `return _ds.insertReceiptWithItems(draft, photoPath: photoPath);`
     (ошибка insert → как сейчас, через `mapScanException`).

### 4. Presentation (scan)
- `ScanController`: приватное `Uint8List? _photoBytes`.
  - `recognizePhoto(bytes)`: `_photoBytes = bytes;` (в начале, до OCR).
  - `save()`: `SaveScannedReceipt(...)(draft, photoBytes: _photoBytes)`.
  - `reset()`: `_photoBytes = null;`.
  - Сами классы `ScanState` не меняются.

### 5. Отображение (receipts) — без изменений
`ReceiptPhotoThumbnail` и экран деталей уже рендерят фото по `photo_path`
(signed URL) и показывают плейсхолдер при `null`/ошибке. После фикса фото
появляется автоматически.

## Поток данных

`pickFromGallery|LiveCamera → recognizePhoto(bytes)` (кэшируем bytes) → OCR →
`ScanReview` → `save()` → usecase(draft, photoBytes) → repo: process+uploadPhoto
(best-effort) → insertReceiptWithItems(draft, photoPath) → `ScanSaved` →
инвалидация списка чеков (уже реализована) → список тянет signed URL → фото видно.

## Обработка ошибок
- Сжатие (`FormatException`) или загрузка (`StorageException`/сеть) → `photo_path = null`,
  чек сохраняется. Плейсхолдер в списке.
- Ошибка `insert` чека → `ScanError` (поведение не меняется).

## Тестирование
- Unit `processReceiptPhoto`: валидное изображение → непустой JPEG; большое →
  ужимается (сторона ≤ 1600); не-изображение → `FormatException`.
- Repo: `photoBytes != null` и upload успешен → `insertReceiptWithItems` получил
  `photoPath` от `uploadPhoto`; upload бросает → insert вызван с `photoPath = null`,
  чек сохранён; `photoBytes == null` → upload не вызывается.
- Controller: после `recognizePhoto(bytes)` + `save()` фейк-репозиторий получил
  непустой `photoBytes`; после `reset()` — очищено.
- Обновить `FakeScanRepository` (захват `photoBytes`) и `FakeScanRemoteDataSource`
  (запись upload/insert, опц. ошибка upload), не ломая существующие тесты.
- Датасорс (Supabase Storage) — без юнит-теста (нужен живой Supabase), как и раньше.

## Документация
- `docs/features/scan.md`: при сохранении скана фото сжимается и грузится в бакет
  `receipts` ({uid}/{ts}.jpg), `photo_path` проставляется в insert; ошибка загрузки
  не блокирует сохранение.
- `docs/features/receipts.md`: для чеков из скана теперь отображается фото.

## Вне скоупа
- Чистка «осиротевшего» фото, если upload прошёл, а insert чека упал (редко) —
  не делаем; задокументировать как известное ограничение.
- Перенос сжатия в isolate (`compute`) — сейчас inline, как у аватара; при тормозах
  на больших фото вынесем отдельно.
- QR-путь (`createReceiptFromQr`) — отдельный цикл.
