/// Назначение: распознанная воркером позиция чека для экрана ревью.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: ScannedItem.
library;

/// Позиция, доставленная сервером (`receipt_items`), редактируемая в ревью.
class ScannedItem {
  const ScannedItem({
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
    this.confidence,
  });

  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;

  /// Уверенность распознавания (0..1) или `null`, если неизвестна.
  final double? confidence;

  /// Порог подсветки сомнительных позиций в ревью.
  static const double kLowConfidence = 0.7;

  /// Уверенность ниже порога (подсветить в ревью).
  bool get lowConfidence => confidence != null && confidence! < kLowConfidence;

  /// Полезная нагрузка позиции для RPC `confirm_receipt`.
  Map<String, dynamic> toConfirmJson() => {
        'raw_name': rawName,
        'qty': qty,
        'unit_price': unitPrice,
        'sum': sum,
      };
}
