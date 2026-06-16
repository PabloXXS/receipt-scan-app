# Фича: receipts

## Назначение
Список и детали чеков; подписка на статус обработки в реальном времени.

## Пользовательские сценарии
- Смотреть список своих (и семейных) чеков.
- Открыть чек: видеть статус (pending/processing/done/failed) и позиции.
- Видеть смену статуса без перезагрузки (Realtime).

## Экраны / UI
- **Список чеков** (`ReceiptsScreen`) — реализован: сортировка по `created_at desc`,
  пагинация (25/страница, подгрузка по скроллу), pull-to-refresh, состояния
  loading/empty/error через каталог дизайн-системы. Строка (`ReceiptListItem`):
  миниатюра фото, название магазина, сумма (`MoneyText`), дата. Статус в списке
  НЕ показываем (всегда «done» для клиентского OCR — шум); он остаётся на экране
  деталей. Сумма берётся из `receipts.total`, который при скане заполняется
  печатным итогом OCR, а при его отсутствии — суммой позиций (`ReceiptDraft.effectiveTotal`).
  Для чеков, сохранённых через скан, миниатюра — реальное фото чека (signed URL
  по `photo_path`); плейсхолдер показывается только если фото не загрузилось.
  Свайп строки (slidable) открывает кнопку-мусорку → диалог подтверждения →
  удаление → перезапрос списка с начала. Тап по строке → детали.
  Ошибка самого удаления (`ReceiptsDeleteFailure`) показывается через SnackBar;
  если удаление прошло, но упал перезапрос списка — SnackBar не показываем
  (ошибка уже отражена в `AppErrorView` списка, иначе была бы двойная и сбивающая
  атрибуция «не удалилось»).
- **Детали чека** (`ReceiptDetailsScreen`) — реализован: шапка (магазин/дата/статус),
  итог, фото, список позиций (`receipt_items`). Без Realtime. Для сканированных
  чеков отображается реальное фото (signed URL по `photo_path`); плейсхолдер —
  только при отсутствии/незагруженном фото.

Название магазина берётся из справочника через PostgREST-эмбед `stores(name)`;
при `store_id = null` (магазин ещё не распознан воркером) показывается фолбэк
«Магазин не определён».

## Задействованные сущности БД
`receipts`, `receipt_items`, `stores` (название магазина). `products` (имена позиций) —
пока не используется (товарный справочник зоны B ещё не создан).

## Репозитории и use-cases
`ReceiptsRepository` (`list({limit, offset})`, `getById`, `delete`, `photoUrl`).
Реализация — `ReceiptsRepositoryImpl` поверх `ReceiptsRemoteDataSource` (PostgREST +
Storage signed URL). Use-case `watchReceipt` (Realtime) — отдельный цикл.

## Riverpod-провайдеры
- `receiptsListControllerProvider` — `AsyncNotifier<ReceiptsListState>` со
  state `items + hasMore + isLoadingMore`; методы `loadMore`/`refresh`/`deleteReceipt`.
- `receiptDetailsProvider(id)` — детали чека.
- `receiptPhotoUrlProvider(path)` — signed URL фото из приватного бакета `receipts`.
- `receiptStatusProvider` (подписка на строку через `core/realtime/`) — НЕ реализован.

## Затрагиваемые RLS-политики
Зона A: `user_id = auth.uid()`. Семейное правило
(`OR family_id = current_user_family_id()`) ещё не добавлено — сейчас список
показывает только свои чеки. `stores`/`chains` — зона B (`select` всем
авторизованным), миграция `0004_stores_chains.sql`.

## Взаимодействие с воркером
Воркер обновляет `status`, проставляет `store_id` и пишет `receipt_items`;
клиент увидит изменения при следующем запросе (Realtime — отдельный цикл).

## Открытые вопросы
- Поведение UI при `failed` (повтор обработки?).
- Realtime-подписка на статус и семейные чеки — отдельные циклы.

## Пагинация
Range/offset по 25 (`kReceiptsPageSize`), сортировка `created_at desc`; после
мутаций — полный refetch с начала. Решение зафиксировано в
`docs/adr/0002-receipts-pagination.md`.
