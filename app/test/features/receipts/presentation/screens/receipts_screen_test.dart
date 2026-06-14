import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_list_item.dart';
import 'package:ticket_app/shared/components/components.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('пустой список → AppEmptyState', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider
            .overrideWithValue(FakeReceiptsRepository([])),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('есть чеки → рендерятся строки списка', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider.overrideWithValue(
          FakeReceiptsRepository(
              [makeReceipt('r1'), makeReceipt('r2'), makeReceipt('r3')]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptListItem), findsNWidgets(3));
  });

  testWidgets('ошибка загрузки → AppErrorView', (tester) async {
    final repo = FakeReceiptsRepository([])
      ..error = Exception('boom'); // станет AsyncError
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [receiptsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);
  });
}
