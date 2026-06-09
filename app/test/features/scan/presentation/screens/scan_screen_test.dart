import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ScanScreen рендерит заголовок и пусто-состояние',
      (tester) async {
    await pumpApp(tester, const ScanScreen());
    expect(find.text('Сканировать'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
