import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/realtime/receipt_realtime.dart';

class _FakeRealtime implements ReceiptRealtime {
  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) => Stream.value([
        {'id': id, 'status': 'review'},
      ]);
  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) =>
      Stream.value([]);
}

void main() {
  test('fake realtime emits receipt row', () async {
    final r = await _FakeRealtime().watchReceipt('r1').first;
    expect(r.single['status'], 'review');
  });
}
