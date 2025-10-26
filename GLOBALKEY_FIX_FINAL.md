# ✅ Решение проблемы "Multiple widgets used the same GlobalKey"

## 🔍 Глубокий анализ причины

### Проблема

```
Multiple widgets used the same GlobalKey.
The key [GlobalObjectKey _ContentState#2c938] was used by multiple widgets.
```

### Корневая причина

`CupertinoTabView` **кэширует весь navigation stack**, чтобы сохранить состояние при переключении между табами. Это означает:

1. При открытии HomePage, создается State с GlobalKey
2. При переходе на ReceiptDetailsPage, HomePage остается в памяти (не dispose)
3. При возврате назад, создается НОВЫЙ экземпляр HomePage State
4. **Оба State существуют одновременно** во время анимации возврата
5. GlobalKey присутствует в обоих экземплярах → конфликт

### Почему GlobalObjectKey(this) не помог?

`GlobalObjectKey(this)` создает уникальный ключ на основе identity объекта State, но проблема в том, что **сам объект State дублируется** из-за кэширования CupertinoTabView.

## ✅ Радикальное решение

**Убрал GlobalKey полностью**, заменив `PopupMenuHelper` на нативный **`CupertinoActionSheet`**.

### Преимущества решения:

1. ✅ **Не требует GlobalKey** - CupertinoActionSheet показывается снизу экрана
2. ✅ **Более нативный для iOS** - соответствует Human Interface Guidelines
3. ✅ **Устраняет root cause** - нет зависимости от позиционирования кнопки
4. ✅ **Стабильная работа** - не зависит от кэширования CupertinoTabView

## 📝 Изменения

### 1. `lib/pages/home_page.dart`

**Было:**

```dart
late final GlobalKey _addButtonKey = GlobalObjectKey(this);

void _showAddMenu(BuildContext context) {
  PopupMenuHelper.show(
    context: context,
    buttonKey: _addButtonKey,
    menuContent: PopupMenuContainer(children: [...]),
  );
}
```

**Стало:**

```dart
// GlobalKey удален полностью

void _showAddMenu(BuildContext context) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: const Text('Добавить чек'),
      actions: <CupertinoActionSheetAction>[
        // Действия меню
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Отмена'),
      ),
    ),
  );
}
```

### 2. `lib/widgets/receipt_wizard/items_info_header.dart`

**Изменения:**

- Убрал `_sortButtonKey: GlobalKey`
- Заменил `PopupMenuHelper` на `CupertinoActionSheet` для сортировки
- Использовал `isDefaultAction` вместо `isSelected` для выделения

### 3. `lib/widgets/receipt_add_sheet.dart`

**Изменения:**

- Убрал `_currencyBtnKey: GlobalKey` (не использовался для позиционирования)

### 4. Дополнительные исправления:

- Заменил устаревший `minSize: 0` на `minimumSize: Size.zero`
- Добавил импорт `SelectableText` из Material

## 🎯 Результат

- ✅ Ошибка "Multiple widgets used the same GlobalKey" полностью устранена
- ✅ Более нативный UX для iOS-пользователей
- ✅ Стабильная работа при навигации и переключении табов
- ✅ Соответствие iOS Human Interface Guidelines

## 📚 Уроки

1. **GlobalKey в CupertinoTabView - опасно**: Из-за кэширования navigation stack, State может существовать в нескольких экземплярах
2. **Используйте нативные компоненты**: CupertinoActionSheet не требует GlobalKey и более подходит для iOS
3. **Глубокий анализ важен**: Поверхностные решения (ValueKey, GlobalObjectKey) не работают, если root cause в архитектуре фреймворка

---

**Дата:** 2025-10-13  
**Статус:** ✅ Полностью исправлено и протестировано
