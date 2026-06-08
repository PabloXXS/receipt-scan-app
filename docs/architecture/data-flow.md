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
