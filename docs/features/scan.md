# Фича: scan

## Назначение
Сканирование QR кассового чека или фотографирование чека, заливка фото в Storage
и создание «сырого» чека в `receipts`.

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
`ScanRepository.saveScannedReceipt(ReceiptDraft)`; use-case `SaveScannedReceipt`.
OCR — `ReceiptOcrEngine` (`VisionOcrEngine`), разбор — `ReceiptParser` (`ReceiptParserImpl`).

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
- Источник позиций — OCR по фото: легального API «позиции по QR» в РБ нет
  (`ch.info-center.by` за reCAPTCHA, без публичного API) — обоснование в спеке 2026-06-14.
- Прежний путь «фото→Storage→pending» (цикл 2026-06-09) удалён как устаревший.

## Открытые вопросы / отложено
- **Фаза 2:** живое AVFoundation-превью с real-time QR-оверлеем.
- Редактирование полей позиций (сейчас только удаление строки свайпом).
- LLM-движок OCR (будущая платная фича); Android-движок OCR.
- Семейное правило RLS (`OR family_id = current_user_family_id()`) — в family-цикле.
- Точность парсера на кириллице/длинных чеках — тюнинг на реальных чеках (устройство).
