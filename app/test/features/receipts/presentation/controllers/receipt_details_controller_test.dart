import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipt_details_controller.dart';

import '../../receipts_test_fakes.dart';

void main() {
  test('receiptDetailsProvider отдаёт чек с позициями', () async {
    final c = ProviderContainer(overrides: [
      receiptsRepositoryProvider
          .overrideWithValue(FakeReceiptsRepository([makeReceipt('r1')])),
    ]);
    addTearDown(c.dispose);
    final details = await c.read(receiptDetailsProvider('r1').future);
    expect(details.receipt.id, 'r1');
    expect(details.items, isNotEmpty);
  });

  test('receiptPhotoUrlProvider отдаёт signed URL', () async {
    final c = ProviderContainer(overrides: [
      receiptsRepositoryProvider.overrideWithValue(FakeReceiptsRepository([])),
    ]);
    addTearDown(c.dispose);
    final url = await c.read(receiptPhotoUrlProvider('uid/x.jpg').future);
    expect(url, 'https://signed/uid/x.jpg');
  });
}
