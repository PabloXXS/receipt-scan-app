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

## Реализовано (цикл 2026-06-09)
- Ветка фото (`source = ocr`): камера/галерея → сжатие → Storage → insert в `receipts`.
- Серверное автозаполнение `user_id`/`country_code`/`family_id` триггером `receipts_fill_owner`.
- Постановка задачи в `pgmq` (`receipts_processing`) триггером `receipts_enqueue`.
- Ограничение фото: ресайз длинной стороны до 1600px, JPEG q85 (`image_compressor`).

## Открытые вопросы / отложено
- QR-скан камерой (`source = qr`) — отдельный цикл (`mobile_scanner` отключён под
  arm64-симулятор; тест на устройстве/Rosetta).
- Семейное правило RLS на `receipts` (`OR family_id = current_user_family_id()`) —
  в family-цикле.
- Чистка осиротевших объектов Storage при сбое insert после успешной загрузки.
- Формат и валидация `qr_raw` по странам.
