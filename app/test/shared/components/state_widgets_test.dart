import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/components.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('AppScaffold показывает заголовок и body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(title: 'Чеки', body: Text('Список')),
      ),
    );
    expect(find.text('Чеки'), findsOneWidget);
    expect(find.text('Список'), findsOneWidget);
  });

  testWidgets('AppLoader показывает индикатор', (tester) async {
    await pumpComponent(tester, const AppLoader());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppEmptyState показывает сообщение', (tester) async {
    await pumpComponent(tester, const AppEmptyState(message: 'Пусто'));
    expect(find.text('Пусто'), findsOneWidget);
  });

  testWidgets('AppErrorView показывает ошибку и кнопку повтора',
      (tester) async {
    var retried = 0;
    await pumpComponent(
      tester,
      AppErrorView(message: 'Ошибка', onRetry: () => retried++),
    );
    expect(find.text('Ошибка'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(retried, 1);
  });
}
