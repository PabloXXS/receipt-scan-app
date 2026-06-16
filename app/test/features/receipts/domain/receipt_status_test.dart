import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  test('fromDb maps review', () {
    expect(ReceiptStatus.fromDb('review'), ReceiptStatus.review);
    expect(ReceiptStatus.fromDb('processing'), ReceiptStatus.processing);
    expect(ReceiptStatus.fromDb('done'), ReceiptStatus.done);
    expect(ReceiptStatus.fromDb('failed'), ReceiptStatus.failed);
    expect(ReceiptStatus.fromDb('unknown'), ReceiptStatus.pending);
  });
}
