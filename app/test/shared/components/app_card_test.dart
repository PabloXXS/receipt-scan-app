import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_card.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает child и реагирует на тап', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppCard(onTap: () => taps++, child: const Text('Контент')),
    );
    expect(find.text('Контент'), findsOneWidget);
    await tester.tap(find.text('Контент'));
    await tester.pump();
    expect(taps, 1);
  });
}
