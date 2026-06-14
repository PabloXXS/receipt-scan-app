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
- Сфотографировать чек (камера/галерея) → OCR распознаёт позиции и QR (УИ) →
  ревью → сохранить `receipt` (`source = ocr`, `status = done`) с позициями.

## Экраны / UI
Экран захвата (камера/галерея), индикатор распознавания, экран-ревью позиций
(итог, удаление строки свайпом, «Сохранить»/«Отмена»), экран успеха.

## Задействованные сущности БД
`receipts` (insert: `status = done`, `source = ocr`, `qr_raw` = УИ, `total`,
`purchased_at`; `country_code`/`family_id`/`currency` — триггером),
`receipt_items` (позиции: `raw_name`, `qty`, `unit_price`, `sum`).

## Репозитории и use-cases
`ScanRepository.saveScannedReceipt(ReceiptDraft, {Uint8List? photoBytes})`;
use-case `SaveScannedReceipt(draft, {photoBytes})` — байты фото опциональны и грузятся
до INSERT. OCR — `ReceiptOcrEngine` (`VisionOcrEngine`), разбор — `ReceiptParser`
(`ReceiptParserImpl`). `ScanController` кэширует байты последнего распознанного фото
(`recognizePhoto`) и передаёт их в `save`; `reset` очищает кэш.

## Riverpod-провайдеры
`scanControllerProvider`, `receiptOcrEngineProvider`, `receiptParserProvider`,
`photoPickerProvider`, `scanRepositoryProvider`.

## Затрагиваемые RLS-политики
Зона A: insert/select/delete `receipts` и `receipt_items` по `auth.uid()`.

## Взаимодействие с воркером
Прямого нет: позиции распознаются на клиенте, чек сохраняется сразу `done`.
Триггер `receipts_enqueue` всё ещё ставит сообщение в `pgmq` (воркер его не читает —
безвредно). Фискальный API/воркерный путь — будущий цикл.

## Реализовано (цикл 2026-06-14 — Фаза 1, iOS)
- Фото чека → Apple Vision (текст `ru` + QR) → парсер позиций (`ReceiptParserImpl`) →
  ревью → сохранение `receipts`+`receipt_items` (`status = done`).
- УИ из QR → `receipts.qr_raw`; валюта — триггером `receipts_fill_owner` из страны
  (BY→BYN, RU→RUB, KZ→KZT).
- Фото чека грузится в бакет `receipts` (JPEG, ≤1600px, q80) и его `photo_path`
  пишется в INSERT (best-effort: при сбое — `photo_path = null`). Подробности — раздел
  «Сохранение и обработка фото».
- Источник позиций — OCR по фото: легального API «позиции по QR» в РБ нет
  (`ch.info-center.by` за reCAPTCHA, без публичного API) — обоснование в спеке 2026-06-14.
- Прежний путь «фото→Storage→pending» (цикл 2026-06-09) удалён как устаревший.

## Открытые вопросы / отложено
- **Фаза 2 (реализовано, цикл 2026-06-14):** живое превью камеры в приложении
  (плагин `camera`) + затвор → существующий OCR-конвейер. Захват вынесен в
  `LiveCameraScreen`; контроллер принимает байты через `recognizePhoto`. Real-time
  QR-оверлей сознательно не делался. Галерея сохранена.
- Редактирование полей позиций (сейчас только удаление строки свайпом).
- LLM-движок OCR (будущая платная фича); Android-движок OCR.
- Семейное правило RLS (`OR family_id = current_user_family_id()`) — в family-цикле.
- Точность парсера на кириллице/длинных чеках — тюнинг на реальных чеках (устройство).
