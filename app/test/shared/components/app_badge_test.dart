import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';
import 'package:ticket_app/shared/components/app_badge.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('success-бейдж показывает текст и красится в success',
      (tester) async {
    await pumpComponent(
      tester,
      const AppBadge(label: 'Готов', tone: AppBadgeTone.success),
    );
    expect(find.text('Готов'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(
          of: find.byType(AppBadge), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppTokens.light.success);
  });
}
