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

  Color _badgeTextColor(WidgetTester tester) {
    final text = tester.widget<Text>(
      find.descendant(of: find.byType(AppBadge), matching: find.byType(Text)),
    );
    return text.style!.color!;
  }

  testWidgets('текст бейджа берёт onSuccess/onWarning из токенов темы (light)',
      (tester) async {
    await pumpComponent(
      tester,
      const AppBadge(label: 'OK', tone: AppBadgeTone.success),
    );
    expect(_badgeTextColor(tester), AppTokens.light.onSuccess);

    await pumpComponent(
      tester,
      const AppBadge(label: 'Внимание', tone: AppBadgeTone.warning),
    );
    expect(_badgeTextColor(tester), AppTokens.light.onWarning);
  });

  testWidgets('текст бейджа тема-зависим (dark): onSuccess отличается от light',
      (tester) async {
    await pumpComponent(
      tester,
      const AppBadge(label: 'OK', tone: AppBadgeTone.success),
      brightness: Brightness.dark,
    );
    expect(_badgeTextColor(tester), AppTokens.dark.onSuccess);
    // В тёмной теме фон success светлый → текст не белый (в отличие от light).
    expect(AppTokens.dark.onSuccess, isNot(AppTokens.light.onSuccess));
  });
}
