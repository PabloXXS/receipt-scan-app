import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_list_item.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_status_badge.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('показывает название магазина и сумму, без бейджа статуса',
      (tester) async {
    await pumpApp(
      tester,
      ReceiptListItem(
        receipt: makeReceipt('r1', storeName: 'Пятёрочка', total: 250),
        onTap: () {},
        onDelete: () async {},
      ),
    );
    expect(find.text('Пятёрочка'), findsOneWidget);
    expect(find.textContaining('250'), findsWidgets);
    // Статус в списке не показываем (только на экране деталей).
    expect(find.byType(ReceiptStatusBadge), findsNothing);
  });

  testWidgets('без названия магазина показывает фолбэк', (tester) async {
    await pumpApp(
      tester,
      ReceiptListItem(
        receipt: makeReceipt('r2', storeName: null),
        onTap: () {},
        onDelete: () async {},
      ),
    );
    expect(find.text('Магазин не определён'), findsOneWidget);
  });
}
