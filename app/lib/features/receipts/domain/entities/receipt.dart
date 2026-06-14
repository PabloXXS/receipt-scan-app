/// Назначение: чек для строки списка (`receipts` + join `stores.name`).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: receipt_status.dart.
/// Ключевые типы: Receipt.
library;

import 'receipt_status.dart';

/// Чек в списке: магазин, сумма, дата, статус, путь к фото.
class Receipt {
  const Receipt({
    required this.id,
    required this.status,
    required this.createdAt,
    this.storeId,
    this.storeName,
    this.total,
    this.currency,
    this.purchasedAt,
    this.photoPath,
  });

  final String id;
  final ReceiptStatus status;
  final DateTime createdAt;
  final String? storeId;

  /// Название магазина из справочника `stores`; null — ещё не распознан.
  final String? storeName;
  final double? total;
  final String? currency;
  final DateTime? purchasedAt;

  /// Путь объекта в приватном бакете `receipts` (нужен signed URL).
  final String? photoPath;
}
