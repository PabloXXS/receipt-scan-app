# API контракты

## Модели данных

### Receipt

```dart
class Receipt {
  String id;                  // UUID
  String userId;              // UUID пользователя
  String? merchantName;       // Название магазина из OCR
  DateTime? purchaseDate;     // Дата покупки
  DateTime? purchaseTime;     // Время покупки
  double total;               // Общая сумма
  String currency;            // Валюта (default: 'RUB')
  String status;              // processing|ready|failed
  String? sourceFileId;       // UUID файла изображения
  String? errorText;          // Текст ошибки (если status = failed)
  double? storeConfidence;    // Уверенность в определении магазина (0-1)
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
}
```

### ReceiptItem

```dart
class ReceiptItem {
  String id;                // UUID
  String receiptId;         // UUID чека
  String name;              // Название товара
  double quantity;          // Количество
  double price;             // Цена за единицу
  String? categoryId;       // UUID категории товара
  String? categoryName;     // Название категории (для отображения)
  DateTime createdAt;
  DateTime updatedAt;
}
```

### ItemCategory

```dart
class ItemCategory {
  String id;                // UUID
  String name;              // Название категории
  String? parentId;         // UUID родительской категории (для иерархии)
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
}
```

## Провайдеры

### receiptsProvider

Возвращает список всех чеков пользователя, отсортированных по дате покупки.

### receiptDetailsProvider(receiptId)

Возвращает кортеж `(Receipt, List<ReceiptItem>)` с деталями чека и списком позиций.

### itemCategoriesProvider

Возвращает список всех категорий товаров для группировки позиций чеков.

## Серверные функции

## POST /analyze

Запуск анализа для загруженного файла чека с автоматическим присвоением категорий товарам.

Request:

```json
{ "file_id": "uuid", "force": false }
```

Response:

```json
{ "receipt_id": "uuid", "status": "processing" }
```

### Процесс анализа

1. **OCR/LLM извлечение данных**:

   - Название магазина (`merchant_name`)
   - Дата и время покупки
   - Список позиций с количеством и ценами
   - Общая сумма и валюта

2. **Автоматическая категоризация товаров**:

   - Загружаются все существующие категории из таблицы `categories`
   - Для каждого товара через OpenAI определяется подходящая категория
   - Если категория найдена, её `id` присваивается позиции (`receipt_items.category_id`)
   - Если подходящей категории нет, поле `category_id` остается `null`

3. **Сохранение результатов**:
   - Создается запись в `receipts` со статусом `ready`
   - Позиции сохраняются в `receipt_items` с присвоенными категориями

### Примеры категоризации

```typescript
// Пример запроса к OpenAI для категоризации
{
  "categories": ["Молочные продукты", "Снеки", "Хозяйственные товары"],
  "items": ["Молоко 3.2%", "Чипсы Lay's", "Туалетная бумага"]
}

// Результат
[
  { "name": "Молоко 3.2%", "category_name": "Молочные продукты" },
  { "name": "Чипсы Lay's", "category_name": "Снеки" },
  { "name": "Туалетная бумага", "category_name": "Хозяйственные товары" }
]
```

Ошибки:

```json
// 400
{ "error": "file_id is required" }

// 401
{ "error": "Unauthorized" }

// 500
{ "error": "OCR failed", "hint": "..." }
```

## POST /status

Проверка статуса обработки чека.

Request:

```json
{ "receipt_id": "uuid" }
```

Response:

```json
{
  "receipt_id": "uuid",
  "status": "ready",
  "merchant_name": "Пятёрочка",
  "total": 1234.56,
  "currency": "RUB",
  "items_count": 15
}
```

## Репозитории

### ReceiptsRepository

```dart
class ReceiptsRepository {
  Future<List<Receipt>> getAllReceipts();
  Future<Receipt> getReceiptById(String id);
  Future<List<ReceiptItem>> getReceiptItems(String receiptId);
}
```

### ItemCategoriesRepository

```dart
class ItemCategoriesRepository {
  Future<List<ItemCategory>> getAllCategories();
  Future<ItemCategory> createCategory(String name);
}
```

## UI/UX Паттерны

### Главная страница (Список чеков)

- Группировка по датам: "Сегодня", "Вчера", "Этот месяц", "Ранее"
- Отображение: название магазина, дата/время, сумма
- Поиск по названию магазина
- Pull-to-refresh для обновления списка

### Детали чека

- Информация: магазин, дата, время, сумма
- Список позиций с категориями (если присвоены)
- Отображение: название товара, количество × цена, категория

### Аналитика

- Общая статистика: количество чеков, общая сумма
- Список доступных категорий товаров
- Возможность создания новых категорий (будущая функциональность)
