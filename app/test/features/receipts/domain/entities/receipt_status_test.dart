import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  test('fromDb мапит значения колонки receipts.status', () {
    expect(ReceiptStatus.fromDb('pending'), ReceiptStatus.pending);
    expect(ReceiptStatus.fromDb('processing'), ReceiptStatus.processing);
    expect(ReceiptStatus.fromDb('done'), ReceiptStatus.done);
    expect(ReceiptStatus.fromDb('failed'), ReceiptStatus.failed);
  });

  test('неизвестное значение → pending (безопасный дефолт)', () {
    expect(ReceiptStatus.fromDb('whatever'), ReceiptStatus.pending);
  });

  test('у каждого статуса есть непустой label', () {
    for (final s in ReceiptStatus.values) {
      expect(s.label, isNotEmpty);
    }
  });
}
