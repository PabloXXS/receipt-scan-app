import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_button.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('primary: показывает лейбл и вызывает onPressed', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'Сохранить', onPressed: () => taps++),
    );
    expect(find.text('Сохранить'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('loading: показывает индикатор и не вызывает onPressed',
      (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'Сохранить', loading: true, onPressed: () => taps++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('рендерится в тёмной теме', (tester) async {
    await pumpComponent(
      tester,
      AppButton(label: 'Ок', onPressed: () {}),
      brightness: Brightness.dark,
    );
    expect(find.text('Ок'), findsOneWidget);
  });
}
