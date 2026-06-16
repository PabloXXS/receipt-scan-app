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
    this.confidence,
  });

  final String id;
  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;

  /// Уверенность распознавания позиции воркером (0..1), `null` если неизвестна.
  final double? confidence;
}
