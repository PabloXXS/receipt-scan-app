# Применение миграции для исправления багов

## Что было исправлено

### 1. Overflow кнопки добавления чека

- **Проблема**:
  - Overflow на 32 пикселя в `CupertinoNavigationBar.trailing`
  - Ошибка "Incorrect use of ParentDataWidget"
  - Причина: `trailing` имеет ограничение в 36px ширины, а две кнопки требуют ~68px
- **Глубокий анализ**:
  ```
  constraints: BoxConstraints(w=36.0, h=32.0)  ← Доступно 36px
  Требуется: 32px + 4px + 32px = 68px          ← Overflow 32px
  ```
- **Решение**: Разделены кнопки по iOS-паттерну в `lib/pages/home_page.dart`:
  - **leading**: Кнопка поиска (CupertinoIcons.search)
  - **trailing**: Кнопка добавления (CupertinoIcons.add_circled)
  - Убраны фоновые Container'ы (использованы чистые иконки)
  - `minSize: 0` для минимального размера
  - Каждая кнопка в своём пространстве без конфликтов

### 2. Закрытие модального окна при сохранении товара

- **Проблема**: При редактировании товара на финальном степе и нажатии "Сохранить" закрывалось всё модальное окно вместо возврата к списку
- **Решение**: Убрал дублирующийся `Navigator.pop()` из `lib/pages/receipt_wizard/edit_item_step.dart`

### 3. Ошибка "column receipts.status does not exist"

- **Проблема**: Приложение пыталось обращаться к колонке `status` которая отсутствовала в БД
- **Решение**: Создана миграция для добавления колонки `status`

## Как применить миграцию

### Вариант 1: Через Supabase Dashboard (рекомендуется)

1. Откройте Supabase Dashboard
2. Перейдите в SQL Editor
3. Скопируйте и выполните следующий SQL:

```sql
-- Убедиться что колонка status существует в таблице receipts
DO $$
BEGIN
    -- Проверяем, существует ли колонка status
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'receipts'
        AND column_name = 'status'
    ) THEN
        -- Добавляем колонку status если её нет
        ALTER TABLE receipts
        ADD COLUMN status text NOT NULL DEFAULT 'processing'
        CHECK (status IN ('processing', 'ready', 'failed'));

        -- Создаём индекс для производительности
        CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);

        RAISE NOTICE '✓ Колонка status успешно добавлена в таблицу receipts';
    ELSE
        RAISE NOTICE '✓ Колонка status уже существует в таблице receipts';
    END IF;
END $$;

-- Обновляем статистику
ANALYZE receipts;

-- Уведомляем PostgREST о перезагрузке схемы
NOTIFY pgrst, 'reload schema';
```

### Вариант 2: Через командную строку (если настроен доступ к БД)

```bash
cd /Users/pablo/work/receipt-scan-app
# Примените миграцию из файла
psql $DATABASE_URL < supabase/migrations/20250117_ensure_status_column.sql
```

## Проверка

После применения миграции:

1. Перезапустите приложение: `flutter run`
2. Проверьте, что:
   - ✅ Кнопка добавления чека остаётся на месте после возврата со страницы деталей
   - ✅ При редактировании товара и нажатии "Сохранить" возвращает только на шаг назад
   - ✅ Нет ошибок "column receipts.status does not exist" в логах

## Дополнительно

Если миграция 20250113 (refactor_categories) ещё не была применена, она также была исправлена для корректной работы.
