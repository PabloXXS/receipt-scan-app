/// Назначение: детали чека — сам чек и его позиции.
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: receipt.dart, receipt_item.dart.
/// Ключевые типы: ReceiptDetails.
library;

import 'receipt.dart';
import 'receipt_item.dart';

/// Чек со списком позиций для экрана деталей.
class ReceiptDetails {
  const ReceiptDetails({required this.receipt, required this.items});

  final Receipt receipt;
  final List<ReceiptItem> items;
}
