/// Назначение: черновик распознанного чека и его позиций (до сохранения).
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: ReceiptDraft, ReceiptItemDraft.
library;

/// Одна распознанная позиция чека.
class ReceiptItemDraft {
  const ReceiptItemDraft({
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
  });

  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;
}

/// Распознанный чек: позиции, печатный итог, дата, УИ из QR.
class ReceiptDraft {
  const ReceiptDraft({
    required this.items,
    this.total,
    this.purchasedAt,
    this.qrRaw,
  });

  final List<ReceiptItemDraft> items;
  final double? total;
  final DateTime? purchasedAt;
  final String? qrRaw;

  /// Сумма распознанных позиций.
  double get itemsSum => items.fold(0, (acc, it) => acc + it.sum);

  /// Сходится ли сумма позиций с печатным итогом (с копеечной погрешностью).
  bool get totalMatches => total != null && (itemsSum - total!).abs() < 0.01;

  /// Возвращает копию без позиции [index] (печатный итог не пересчитывается).
  ReceiptDraft removeItemAt(int index) => ReceiptDraft(
        items: [...items]..removeAt(index),
        total: total,
        purchasedAt: purchasedAt,
        qrRaw: qrRaw,
      );
}
