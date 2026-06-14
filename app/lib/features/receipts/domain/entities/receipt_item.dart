/// Назначение: позиция чека для экрана деталей.
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: нет.
/// Ключевые типы: ReceiptItem.
library;

/// Одна позиция чека (`receipt_items`).
class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
  });

  final String id;
  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;
}
