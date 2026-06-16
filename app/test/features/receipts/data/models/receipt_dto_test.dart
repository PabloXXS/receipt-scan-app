import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/models/receipt_dto.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  test('receiptFromRow читает поля и эмбед stores(name)', () {
    final r = receiptFromRow({
      'id': 'r1',
      'store_id': 's1',
      'stores': {'name': 'Пятёрочка'},
      'total': '123.45',
      'currency': 'RUB',
      'status': 'done',
      'purchased_at': '2026-06-14T10:00:00Z',
      'created_at': '2026-06-14T10:05:00Z',
      'photo_path': 'uid/r1.jpg',
    });
    expect(r.id, 'r1');
    expect(r.storeName, 'Пятёрочка');
    expect(r.total, 123.45);
    expect(r.currency, 'RUB');
    expect(r.status, ReceiptStatus.done);
    expect(r.photoPath, 'uid/r1.jpg');
  });

  test('receiptFromRow без stores и total → null-поля, статус-дефолт', () {
    final r = receiptFromRow({
      'id': 'r2',
      'store_id': null,
      'stores': null,
      'total': null,
      'currency': null,
      'status': null,
      'purchased_at': null,
      'created_at': '2026-06-14T10:05:00Z',
      'photo_path': null,
    });
    expect(r.storeName, isNull);
    expect(r.total, isNull);
    expect(r.status, ReceiptStatus.pending);
  });

  test('receiptItemFromRow парсит числовые поля из строк/чисел', () {
    final it = receiptItemFromRow({
      'id': 'i1',
      'raw_name': 'Молоко',
      'qty': 2,
      'unit_price': '80.5',
      'sum': 161,
    });
    expect(it.rawName, 'Молоко');
    expect(it.qty, 2);
    expect(it.unitPrice, 80.5);
    expect(it.sum, 161);
  });
}
