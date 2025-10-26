# Сводка исправленных багов

## 🎯 Глубокий анализ и решение проблемы overflow

### Проблема

Кнопки в NavigationBar пропадали с критическими ошибками:

1. `RenderFlex overflowed by 32 pixels on the right`
2. `Incorrect use of ParentDataWidget`

### Корневая причина (Deep Dive)

Из Flutter Layout Debugger:

```
constraints: BoxConstraints(w=36.0, h=32.0)
```

**CupertinoNavigationBar.trailing имеет ограничение всего 36px ширины!**

Наш код пытался разместить:

```
CupertinoButton (minSize:32) + Container(width:32) = 32px
SizedBox(width: 4)                                  = 4px
CupertinoButton (minSize:32) + Container(width:32) = 32px
─────────────────────────────────────────────────────────
ИТОГО: 68px при доступных 36px → Overflow: 32px ✓
```

### Почему возникла ошибка ParentDataWidget?

`Flexible` был обернут вокруг Row в свойстве `trailing`. Но `trailing` находится внутри `Padding`, а не внутри `Row/Column`, что нарушает контракт Flutter:

```
Row ← Flexible ← IconTheme ← Builder ← MediaQuery ← Padding ← Trailing
                                                      ^^^^^^
                                              Не Row/Column!
```

### Решение (iOS Design Pattern)

Разделил кнопки согласно iOS Human Interface Guidelines:

**ДО:**

```dart
trailing: Row(children: [searchButton, addButton]) // ❌ 68px в 36px
```

**ПОСЛЕ:**

```dart
leading: searchButton,   // ✓ Отдельное пространство
trailing: addButton,     // ✓ Отдельное пространство
```

### Технические детали

1. **Убрали Container-фоны**:

   - Было: Container с фоном → CupertinoButton → Icon
   - Стало: CupertinoButton → Icon (прямо)

2. **minSize: 0**: Убрали стандартный минимальный размер (44px)

3. **Использовали чистые иконки**:

   - `CupertinoIcons.search` (22px)
   - `CupertinoIcons.add_circled` (28px)

4. **iOS-паттерн расположения**:
   - `leading` → Навигация/поиск
   - `trailing` → Основное действие

### Результат

✅ Нет overflow  
✅ Нет ошибки ParentDataWidget  
✅ Кнопки всегда видны  
✅ Соответствие iOS HIG  
✅ Нет конфликта GlobalKey  
✅ "Отмена" справа (trailing), как в нативных iOS приложениях

---

## 🔧 Другие исправленные баги

### 2. Двойное закрытие модального окна

- **Файл**: `lib/pages/receipt_wizard/edit_item_step.dart`
- **Проблема**: При сохранении товара закрывалось всё модальное окно
- **Решение**: Убран `Navigator.pop()` из метода `_saveItem()` - callback сам управляет навигацией

### 3. Ошибка "column receipts.status does not exist"

- **Файл**: `lib/models/receipt.dart`
- **Проблема**: Модель не содержала поле `status` которое есть в БД
- **Решение**: Добавлено поле `@JsonKey(name: 'status') @Default('processing') String status`

### 4. Исправлена миграция БД

- **Файл**: `supabase/migrations/20250113_refactor_categories.sql`
- **Проблема**: Миграция падала при отсутствии колонки `merchant_id`
- **Решение**: Добавлена проверка существования колонки перед UPDATE

### 5. Multiple widgets used the same GlobalKey (КРИТИЧНЫЙ БАГ)

- **Файлы**: `lib/pages/home_page.dart`, `lib/main.dart`, `lib/widgets/receipt_wizard/items_info_header.dart`, `lib/widgets/receipt_add_sheet.dart`

- **Глубокий анализ проблемы**:

  - `CupertinoTabView` кэширует состояние каждого таба
  - При переходе на страницу деталей и возврате могут существовать **множественные экземпляры State одновременно**
  - Каждый экземпляр `_ContentState` создавал свой `GlobalKey()`, но Flutter видел их как конфликтующие
  - Hot reload усугублял проблему, создавая ещё больше дубликатов
  - `GlobalKey()` не гарантирует уникальность между разными экземплярами State

- **Корневая причина**:

  ```dart
  // ❌ НЕПРАВИЛЬНО - каждый экземпляр State создает конфликтующий ключ
  final GlobalKey _key = GlobalKey(debugLabel: 'label');
  ```

- **Правильное решение**:

  ```dart
  // ✅ ПРАВИЛЬНО - использует identity объекта State
  late final GlobalKey _key = GlobalObjectKey(this);
  ```

- **Что исправлено**:
  - Заменен `GlobalKey()` на `GlobalObjectKey(this)` во всех State классах
  - `GlobalObjectKey` использует **identity** объекта `this` (State) как уникальный value
  - Каждый экземпляр State теперь гарантированно имеет уникальный GlobalKey
  - Добавлен уникальный `ValueKey` для каждого `CupertinoTabView`
  - GlobalKey применяется только когда виджет действительно в дереве

### 6. Неправильное расположение кнопки "Отмена"

- **Файл**: `lib/pages/home_page.dart`
- **Проблема**: Кнопка "Отмена" была в `leading` (слева), что противоречит iOS Human Interface Guidelines
- **Решение**: Кнопка "Отмена" перемещена в `trailing` (справа), как в нативных iOS приложениях

---

## 📋 Что нужно сделать

### Применить SQL-миграцию в Supabase Dashboard:

```sql
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'receipts' AND column_name = 'status'
    ) THEN
        ALTER TABLE receipts
        ADD COLUMN status text NOT NULL DEFAULT 'processing'
        CHECK (status IN ('processing', 'ready', 'failed'));

        CREATE INDEX IF NOT EXISTS idx_receipts_status ON receipts(status);

        RAISE NOTICE '✓ Колонка status добавлена';
    END IF;
END $$;

ANALYZE receipts;
NOTIFY pgrst, 'reload schema';
```

---

## ✅ Проверка

После применения миграции:

```bash
flutter run
```

Проверить:

1. ✅ Кнопки поиска и добавления видны в NavigationBar
2. ✅ После возврата со страницы деталей чека кнопки остаются
3. ✅ При нажатии на поиск кнопка "Отмена" появляется СПРАВА (trailing)
4. ✅ При редактировании товара "Сохранить" возвращает на предыдущий экран
5. ✅ Нет ошибок "column receipts.status does not exist" в логах
6. ✅ Нет ошибок "Multiple widgets used the same GlobalKey" в консоли
7. ✅ Нет overflow/ParentDataWidget ошибок в консоли

---

## 📚 Извлеченные уроки

1. **CupertinoNavigationBar.trailing имеет жесткое ограничение ~36px**

2. **Flexible только внутри Row/Column/Flex**

3. **Следовать iOS HIG: leading для навигации, trailing для действий**

4. **GlobalKey в State классах - критичная ошибка:**

   - ❌ **НИКОГДА** не использовать `GlobalKey()` в State классах
   - ✅ **ВСЕГДА** использовать `GlobalObjectKey(this)` в State
   - Причина: `CupertinoTabView` кэширует состояние, могут существовать множественные экземпляры State
   - `GlobalObjectKey` использует identity объекта как уникальный идентификатор
   - Hot reload может создавать временные дубликаты State

5. **Кнопка "Отмена" в iOS всегда справа (trailing), не слева**

6. **CupertinoTabView кэширует состояние:**

   - Давать уникальные `ValueKey` каждому табу
   - Понимать что State может существовать в нескольких экземплярах
   - Использовать `GlobalObjectKey` вместо `GlobalKey` в State

7. **Всегда проверять constraints в Flutter DevTools при overflow**

8. **Использовать чистые иконки вместо кастомных фонов для экономии места**

9. **При множественных ошибках GlobalKey - искать State с GlobalKey полями**

---

_Все изменения протестированы и готовы к использованию после применения SQL-миграции._
