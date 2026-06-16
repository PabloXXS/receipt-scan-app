# Поток обработки чека

1. Пользователь делает фото (или сканирует QR) → Flutter заливает фото в Storage
   и вставляет «сырой» чек в `receipts` (`status = processing`, `source = ocr|qr`,
   `country_code` из профиля).
2. Триггер на `receipts` кладёт сообщение `{receipt_id}` в очередь `pgmq`.
3. Воркер читает сообщение (`pgmq.read` с visibility-timeout). На текущем этапе
   фискального API нет — основной путь OCR: воркер скачивает фото и вызывает
   OCR-сервис (PaddleOCR + магазин-агностичный парсер, см.
   `superpowers/specs/2026-06-15-server-side-ocr-design.md`), который возвращает
   готовые позиции. (Фискальный провайдер по `country_code` — будущий путь.)
4. Воркер пишет `receipt_items` и ставит `receipts.status = review` (ожидание
   подтверждения пользователем) либо `failed` + `error`. Нормализация товаров
   (сырое название → канонический `products` через `product_aliases`) — будущий цикл.
5. **Анонимизация:** воркер кладёт обезличенные наблюдения цен
   (`product_id, store_id, region, price, currency, observed_at` — без `user_id`
   и `family_id`) в `prices` (см. `privacy.md`).
6. Flutter через **Realtime** подписан на свою строку `receipts` → видит статус
   `review` и подтягивает позиции на экран-ревью.
7. Пользователь правит/подтверждает → клиент вызывает RPC `confirm_receipt`
   (`SECURITY DEFINER`): фиксирует позиции, `status = done`, пересчёт `total`.
   Обходит запрет клиентского `UPDATE receipts`, не расширяя UPDATE-RLS.

## Очередь

Выбран `pgmq` (см. `adr/0001-pgmq-queue.md`): устойчивость к долгим фискальным
запросам, ретраи и visibility-timeout «из коробки», не выходя за пределы
Postgres/Supabase. `JobConsumer` в воркере: успех → `pgmq.delete`, ошибка →
инкремент попыток, исчерпание → `pgmq.archive` + `receipts.status = failed`.
