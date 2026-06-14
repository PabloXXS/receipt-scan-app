import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

void main() {
  ReceiptDraft draft() => ReceiptDraft(
        items: const [
          ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
          ReceiptItemDraft(rawName: 'B', qty: 1, unitPrice: 3, sum: 3),
        ],
        total: 5,
        purchasedAt: DateTime(2026, 6, 10),
        qrRaw: 'УИ1',
      );

  test('itemsSum суммирует позиции', () {
    expect(draft().itemsSum, 5);
  });

  test('totalMatches=true когда сумма позиций ≈ total', () {
    expect(draft().totalMatches, isTrue);
  });

  test('removeItemAt возвращает новый draft без позиции', () {
    final d = draft().removeItemAt(0);
    expect(d.items.length, 1);
    expect(d.items.first.rawName, 'B');
    expect(d.total, 5); // печатный итог не пересчитываем
  });
}
