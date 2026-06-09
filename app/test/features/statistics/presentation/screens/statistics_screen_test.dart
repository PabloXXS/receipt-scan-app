import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('StatisticsScreen рендерит заголовок и пусто-состояние',
      (tester) async {
    await pumpApp(tester, const StatisticsScreen());
    expect(find.text('Статистика'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
