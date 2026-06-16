# Фича: scan

## Назначение
Сканирование QR кассового чека или фотографирование чека, заливка фото в Storage
и создание «сырого» чека в `receipts`.

## Сохранение и обработка фото
При сохранении скана фото сжимается в JPEG (`core/images/receipt_image_processor.dart`,
длинная сторона ≤1600px, качество q80) и грузится в приватный бакет `receipts` по пути
`{uid}/{ts}.jpg`. Полученный `photo_path` проставляется прямо в INSERT чека (клиентский
UPDATE у `receipts` запрещён RLS, поэтому путь нельзя «дописать» позже). Загрузка — best-effort:
при ошибке сжатия или загрузки чек всё равно сохраняется с `photo_path = null`. Известное
ограничение: если INSERT упадёт уже после успешной загрузки фото, файл остаётся осиротевшим
в бакете (чистка — отдельная задача).

## Пользовательские сценарии
- Сфотографировать чек (камера/галерея) → загрузка фото + создание чека
  (`source = ocr`, `status = processing`) → серверный OCR (воркер + OCR-сервис)
  распознаёт позиции → клиент по Realtime получает `status = review` и позиции →
  экран-ревью (с подсветкой неуверенно распознанных) → подтверждение
  (`confirm_receipt` → `status = done`). QR (УИ) детектится на устройстве (QR-only).

## Экраны / UI
Экран захвата (камера/галерея), вид «Распознаём чек…» (processing, ожидание воркера),
экран-ревью позиций (подсветка низкого `confidence` иконкой+бейджем, итог, удаление
строки свайпом, «Подтвердить»/«Отмена»), экран успеха.

## Задействованные сущности БД
`receipts` (insert клиентом: `status = processing`, `source = ocr`, `qr_raw` = УИ,
`photo_path`; `country_code`/`family_id`/`currency` — триггером). Воркер пишет
`receipt_items` (`raw_name`, `qty`, `unit_price`, `sum`, `confidence`) и ставит
`status = review`. Подтверждение — RPC `confirm_receipt(p_receipt_id, p_items)`
(`SECURITY DEFINER`): фиксирует позиции, `status = done`, пересчёт `total`.

## Репозитории и use-cases
`ScanRepository.startScan({Uint8List? photoBytes, String? qrRaw})` — загрузка фото
(best-effort) + `INSERT receipts(status=processing)`, возвращает id;
`ScanRepository.confirm(receiptId, items)` — вызов RPC `confirm_receipt`. QR — `QrScanner`
(`VisionQrScanner`, нативный канал `scan/qr`). Realtime — `ReceiptRealtime`
(`watchReceipt`/`watchItems`, supabase `.stream()`). `ScanController` (sealed-состояния
Idle/Uploading/Processing/Review/Confirming/Saved/Error) подписывается на строку чека и
по `review` собирает позиции; `confirm` подтверждает, `reset` сбрасывает и снимает
подписку.

## Riverpod-провайдеры
`scanControllerProvider`, `qrScannerProvider`, `receiptRealtimeProvider`,
`photoPickerProvider`, `scanRepositoryProvider`.

## Затрагиваемые RLS-политики
Зона A: insert/select/delete `receipts` и `receipt_items` по `auth.uid()`.

## Взаимодействие с воркером
**Переходное состояние (цикл серверного OCR, 2026-06-15..16).** Серверный путь
распознавания реализован (планы `superpowers/plans/2026-06-15-*`): PHP-воркер читает
`pgmq`, скачивает фото из Storage, вызывает OCR-сервис (PaddleOCR + магазин-агностичный
парсер, `ocr-service/`), пишет `receipt_items` с `confidence` и ставит `status=review`;
клиент подтверждает чек через RPC `confirm_receipt` (`status=done`, пересчёт `total`).
См. спеку `superpowers/specs/2026-06-15-server-side-ocr-design.md`.

Клиент переключён на async-поток (план `superpowers/plans/2026-06-16-client-async-scan.md`):
`INSERT receipts(status=processing)` → Realtime-подписка → экран-ревью серверных позиций
с подсветкой confidence → `confirm_receipt`. iOS-Vision обрезан до QR-only. Фискальный
API — отдельный будущий цикл (`FetchFiscalDataStep` пока Null-путь).

## Реализовано (цикл серверного OCR, 2026-06-15..16)
- **Сервер:** OCR-сервис (`ocr-service/`, PaddleOCR 2.x cyrillic + магазин-агностичный
  парсер: геометрия + арифметика `a×b≈c` + классы лексем, без правил под магазин) →
  PHP-воркер (`pgmq` → Storage → OCR-сервис → `receipt_items`+`confidence` →
  `status=review`) → RPC `confirm_receipt` (`review→done`, пересчёт `total`).
- **Клиент:** фото (камера/галерея) → upload + `INSERT receipts(status=processing)` →
  Realtime → экран-ревью (подсветка низкого `confidence` иконкой+бейджем, удаление
  свайпом) → `confirm_receipt`. QR (УИ) — нативный QR-only канал `scan/qr`.
- **Удалено:** on-device текст-OCR (Apple Vision `VNRecognizeTextRequest`), Dart-парсер
  `ReceiptParserImpl`, `ReceiptDraft`, `SaveScannedReceipt`, синхронное сохранение `done`.
- Фото грузится в бакет `receipts` (JPEG, ≤1600px, q80), `photo_path` — в INSERT
  (best-effort). Подробности — раздел «Сохранение и обработка фото».
- Прежний клиентский Vision-путь (цикл 2026-06-14) заменён серверным OCR.

## Открытые вопросы / отложено
- Полноценное редактирование полей позиций в ревью (сейчас — только удаление строки).
- `AppBadge`: завести `onWarning/onSuccess`-токены вместо хардкода `Colors.white/black87`
  (контраст в тёмной теме) — всплыло при дизайн-ревью.
- `_loadReviewItems` использует `.stream().first`; рассмотреть одноразовый PostgREST-запрос.
- Realtime требует включённой публикации на `receipts`/`receipt_items` (настройка проекта).
- Апгрейд OCR на PaddleOCR 3.x / PP-OCRv5 (выше точность кириллицы).
- Семейное правило RLS (`OR family_id = current_user_family_id()`) — в family-цикле.
- Точность парсера на реальных чеках разных сетей — тюнинг (относительные пороги,
  одноколоночные чеки «только сумма»).
