import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_details.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_item.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  final createdAt = DateTime.utc(2026, 6, 14, 10);

  test('Receipt хранит переданные поля', () {
    final r = Receipt(
      id: 'r1',
      storeName: 'Пятёрочка',
      total: 123.45,
      currency: 'RUB',
      status: ReceiptStatus.done,
      purchasedAt: createdAt,
      createdAt: createdAt,
      photoPath: 'uid/r1.jpg',
    );
    expect(r.id, 'r1');
    expect(r.storeName, 'Пятёрочка');
    expect(r.total, 123.45);
    expect(r.status, ReceiptStatus.done);
  });

  test('ReceiptDetails объединяет чек и позиции', () {
    final r = Receipt(
      id: 'r1',
      status: ReceiptStatus.done,
      createdAt: createdAt,
    );
    const item = ReceiptItem(
        id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80);
    final d = ReceiptDetails(receipt: r, items: [item]);
    expect(d.receipt.id, 'r1');
    expect(d.items.single.rawName, 'Молоко');
  });
}
