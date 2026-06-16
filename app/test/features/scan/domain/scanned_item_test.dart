import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/entities/scanned_item.dart';

void main() {
  test('lowConfidence threshold', () {
    expect(
      const ScannedItem(
              rawName: 'A', qty: 1, unitPrice: 1, sum: 1, confidence: 0.5)
          .lowConfidence,
      isTrue,
    );
    expect(
      const ScannedItem(
              rawName: 'A', qty: 1, unitPrice: 1, sum: 1, confidence: 0.9)
          .lowConfidence,
      isFalse,
    );
    expect(
      const ScannedItem(rawName: 'A', qty: 1, unitPrice: 1, sum: 1)
          .lowConfidence,
      isFalse,
    );
  });

  test('toConfirmJson shape for confirm_receipt', () {
    const i = ScannedItem(
        rawName: 'Молоко', qty: 2, unitPrice: 1.25, sum: 2.5, confidence: 0.8);
    expect(i.toConfirmJson(), {
      'raw_name': 'Молоко',
      'qty': 2.0,
      'unit_price': 1.25,
      'sum': 2.5,
    });
  });
}
