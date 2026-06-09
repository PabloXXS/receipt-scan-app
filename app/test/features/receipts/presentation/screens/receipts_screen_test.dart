import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ReceiptsScreen рендерит заголовок и пусто-состояние',
      (tester) async {
    await pumpApp(tester, const ReceiptsScreen());
    expect(find.text('Чеки'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
