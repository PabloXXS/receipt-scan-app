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
