# Поддержка темной темы - Обязательные правила

## 🎯 КРИТИЧЕСКИ ВАЖНО: Всегда поддерживать темную тему!

### ❌ НЕ ДЕЛАТЬ:

```dart
// НЕПРАВИЛЬНО - статичные цвета
color: CupertinoColors.label,
color: CupertinoColors.systemBackground,
color: CupertinoColors.separator,
```

### ✅ ПРАВИЛЬНО:

```dart
// ПРАВИЛЬНО - адаптивные цвета
color: CupertinoColors.label.resolveFrom(context),
color: CupertinoColors.systemBackground.resolveFrom(context),
color: CupertinoColors.separator.resolveFrom(context),
```

## 📋 Чек-лист для каждого UI элемента:

### 1. **Цвета фона**

- ✅ `CupertinoColors.systemBackground.resolveFrom(context)`
- ✅ `CupertinoColors.systemGrey6.resolveFrom(context)`

### 2. **Цвета текста**

- ✅ `CupertinoColors.label.resolveFrom(context)` - основной текст
- ✅ `CupertinoColors.secondaryLabel.resolveFrom(context)` - вторичный текст
- ✅ `CupertinoColors.tertiaryLabel.resolveFrom(context)` - третичный текст

### 3. **Цвета разделителей**

- ✅ `CupertinoColors.separator.resolveFrom(context)`

### 4. **Цвета иконок**

- ✅ `CupertinoColors.label.resolveFrom(context)` - основные иконки (адаптивные)
- ✅ `CupertinoColors.tertiaryLabel.resolveFrom(context)` - декоративные иконки

### 5. **Цвета ошибок**

- ✅ `CupertinoColors.systemRed` - иконки ошибок (статические)

## 🔧 Паттерн исправления:

### Было:

```dart
const TextStyle(
  color: CupertinoColors.label,
)
```

### Стало:

```dart
TextStyle(
  color: CupertinoColors.label.resolveFrom(context),
)
```

## 🎨 Цветовая схема в темной теме:

| Элемент            | Светлая тема       | Темная тема       |
| ------------------ | ------------------ | ----------------- |
| `systemBackground` | Белый              | Черный            |
| `label`            | Черный             | Белый             |
| `secondaryLabel`   | Серый              | Светло-серый      |
| `tertiaryLabel`    | Светло-серый       | Темно-серый       |
| `separator`        | Светло-серый       | Темно-серый       |
| `systemGrey6`      | Очень светло-серый | Очень темно-серый |

## ⚠️ ВАЖНО:

- **ВСЕГДА** используй `.resolveFrom(context)` для адаптивных цветов
- **НИКОГДА** не используй статичные цвета для текста и фона
- **ТЕСТИРУЙ** в обеих темах перед коммитом
- **ПОМНИ**: пользователи ожидают корректной работы темной темы!

## 🎨 Специальные правила для темной темы:

- **Подложки кнопок**: `CupertinoColors.systemGrey6.resolveFrom(context)` (темно-серый в темной теме)
- **Иконки в кнопках**: `CupertinoColors.label.resolveFrom(context)` (черные в темной теме)
- **Фон лоадера**: `CupertinoColors.systemBackground.resolveFrom(context)` (как у страницы)
- **Header при скроллинге**: `CupertinoColors.systemBackground.resolveFrom(context)` (не белый!)

## 🚀 Результат:

- Автоматическая адаптация к системной теме
- Корректное отображение в светлой и темной темах
- Соответствие iOS Human Interface Guidelines
- Улучшенный UX для всех пользователей
