import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipt_details_screen.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_status_badge.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('рендерит магазин, статус и позиции чека', (tester) async {
    await pumpApp(
      tester,
      const ReceiptDetailsScreen(id: 'r1'),
      overrides: [
        receiptsRepositoryProvider.overrideWithValue(
          FakeReceiptsRepository([makeReceipt('r1', storeName: 'Лента')]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Лента'), findsOneWidget);
    expect(find.byType(ReceiptStatusBadge), findsOneWidget);
    expect(find.text('Молоко'), findsOneWidget);
  });
}
