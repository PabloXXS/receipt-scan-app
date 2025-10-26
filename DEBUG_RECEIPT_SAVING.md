# Отладка сохранения чека

## Проблемы

### Проблема 1: Чек не добавлялся в категорию после сохранения

**Причина:** В приложении используется запутанная терминология:

- **Таблица `merchants`** используется как **категории чеков** (не магазины!)
- **CategoryReceiptsPage** использует `categoryReceiptsProvider`
- Ранее обновлялся неправильный провайдер: `merchantReceiptsProvider` вместо `categoryReceiptsProvider`

**Статус:** ✅ Исправлено

### Проблема 2: Чек сохраняется только в существующие категории (ProStore и т.д.)

**Причина:** Может отсутствовать RLS политика для создания новых категорий (INSERT в таблицу `merchants`)

**Статус:** ⚠️ Требуется проверка БД

## Исправления

### 1. receipt_wizard_provider.dart

- ✅ Изменён импорт: `merchant_receipts_provider` → `category_receipts_provider`
- ✅ В `_refreshLists()` теперь обновляется `categoryReceiptsProvider`
- ✅ Добавлено подробное логирование всех этапов сохранения

### 2. category_receipts_provider.dart

- ✅ Добавлено логирование загрузки чеков

### 3. category_receipts_repository.dart

- ✅ Добавлено логирование запросов к БД

### 4. category_receipts_page.dart

- ✅ Добавлено логирование рендеринга страницы

## Как проверить логи

1. Запустите приложение в режиме отладки:

   ```bash
   flutter run -d macos
   ```

2. Откройте консоль в IDE

3. Создайте новый чек и сохраните его

4. В консоли вы увидите последовательность логов:
   ```
   📝 [RECEIPT_WIZARD] saveReceipt вызван
   📝 [RECEIPT_WIZARD] Валидация пройдена. Категория: <название>
   📝 [RECEIPT_WIZARD] userId: <id>
   🔍 [RECEIPT_WIZARD] Поиск категории: <название>
   ✅ [RECEIPT_WIZARD] Категория найдена. ID: <id>
   📝 [RECEIPT_WIZARD] categoryId (merchant_id): <id>
   📝 [RECEIPT_WIZARD] Создаём чек с данными: {...}
   📝 [RECEIPT_WIZARD] Чек создан. receiptId: <id>
   📝 [RECEIPT_WIZARD] Добавлено N позиций чека
   🔄 [RECEIPT_WIZARD] Обновление провайдеров. categoryId: <id>
   🔄 [RECEIPT_WIZARD] categoryGroupsProvider обновлён
   🔄 [RECEIPT_WIZARD] categoryReceiptsProvider(<id>) обновлён
   📝 [RECEIPT_WIZARD] Чек успешно сохранён и провайдеры обновлены
   📦 [CATEGORY_RECEIPTS_PROVIDER] build() вызван для categoryId: <id>
   📚 [CATEGORY_RECEIPTS_REPO] Загрузка чеков для категории: <id>
   📚 [CATEGORY_RECEIPTS_REPO] Получено N чеков для категории <id>
   📦 [CATEGORY_RECEIPTS_PROVIDER] Получено N чеков
   📄 [CATEGORY_RECEIPTS_PAGE] build() вызван для категории: <название> (id: <id>)
   ```

## Проверка RLS политик

### 1. Проверьте политики в Supabase SQL Editor

Выполните скрипт `check_policies.sql`:

```bash
# Откройте Supabase Dashboard -> SQL Editor -> New Query
# Вставьте содержимое файла check_policies.sql
```

Убедитесь что есть **3 политики** для `merchants`:

1. ✅ `Users can view all merchants` (SELECT)
2. ✅ `Users can create merchants` (INSERT)
3. ✅ `Users can update merchants` (UPDATE)

### 2. Если политик нет - примените миграции

```bash
# Проверьте статус миграций
supabase migration list --linked

# Если миграции не применены полностью, сбросьте БД
supabase db reset --linked --yes
```

### 3. Проверьте логи при создании новой категории

При попытке создать чек в **новую категорию**, в консоли должны быть логи:

```
🔍 [RECEIPT_WIZARD] Поиск категории: НоваяКатегория
🔍 [RECEIPT_WIZARD] Результат поиска: 0 категорий
➕ [RECEIPT_WIZARD] Категория не найдена. Создаём новую
➕ [RECEIPT_WIZARD] Ответ от БД при создании: {id: xxx, name: НоваяКатегория, ...}
✅ [RECEIPT_WIZARD] Новая категория создана. ID: xxx
```

**Если видите ошибку:**

```
❌ [RECEIPT_WIZARD] Ошибка при работе с категорией "...": new row violates row-level security policy
```

Это означает **отсутствие RLS политики** для INSERT в таблицу `merchants`.

### 4. Проверьте чеки в БД

Если чек не появляется, выполните SQL запрос в Supabase:

```sql
SELECT
  r.id,
  r.merchant_id,
  r.total,
  r.status,
  r.is_deleted,
  m.name as merchant_name
FROM receipts r
LEFT JOIN merchants m ON r.merchant_id = m.id
WHERE r.user_id = '<your-user-id>'
ORDER BY r.created_at DESC
LIMIT 10;
```

Проверьте:

- ✅ Чек создался в БД
- ✅ `merchant_id` соответствует ID категории
- ✅ `status` = 'ready'
- ✅ `is_deleted` = false

## Префиксы логов

- 📝 - Основные операции сохранения
- 🔍 - Поиск данных
- ✅ - Успешное выполнение
- ➕ - Создание новой записи
- 🔄 - Обновление провайдеров
- 📦 - Провайдеры
- 📚 - Репозитории
- 📄 - UI страницы
- ❌ - Ошибки
