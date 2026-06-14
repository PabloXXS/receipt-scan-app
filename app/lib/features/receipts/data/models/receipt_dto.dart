/// Назначение: маппинг строк PostgREST в доменные Receipt/ReceiptItem.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: domain/entities (receipt.dart, receipt_item.dart, receipt_status.dart).
/// Ключевые типы: receiptFromRow, receiptItemFromRow, kReceiptColumns.
library;

import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_item.dart';
import '../../domain/entities/receipt_status.dart';

/// Колонки чека для select списка (+ эмбед названия магазина).
const String kReceiptColumns =
    'id, store_id, total, currency, status, purchased_at, created_at, '
    'photo_path, stores(name)';

/// Колонки позиции чека.
const String kReceiptItemColumns = 'id, raw_name, qty, unit_price, sum';

/// numeric из PostgREST может прийти как num или String — приводим к double.
double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _toDate(Object? v) =>
    v == null ? null : DateTime.parse(v.toString()).toLocal();

/// Строка `receipts` (с эмбедом `stores(name)`) → [Receipt].
Receipt receiptFromRow(Map<String, dynamic> row) {
  final store = row['stores'];
  final storeName = store is Map ? store['name'] as String? : null;
  return Receipt(
    id: row['id'] as String,
    storeId: row['store_id'] as String?,
    storeName: storeName,
    total: _toDouble(row['total']),
    currency: row['currency'] as String?,
    status: ReceiptStatus.fromDb(row['status'] as String?),
    purchasedAt: _toDate(row['purchased_at']),
    createdAt: _toDate(row['created_at'])!,
    photoPath: row['photo_path'] as String?,
  );
}

/// Строка `receipt_items` → [ReceiptItem].
ReceiptItem receiptItemFromRow(Map<String, dynamic> row) => ReceiptItem(
      id: row['id'] as String,
      rawName: row['raw_name'] as String? ?? '',
      qty: _toDouble(row['qty']) ?? 0,
      unitPrice: _toDouble(row['unit_price']) ?? 0,
      sum: _toDouble(row['sum']) ?? 0,
    );
