/// Назначение: хелпер для widget-тестов — оборачивает виджет в MaterialApp с темой приложения.
///
/// Слой: test/helpers
/// Зависимости: flutter_test, core/theme/app_theme.dart.
/// Ключевые типы: pumpComponent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_theme.dart';

/// Рендерит [child] внутри MaterialApp со светлой или тёмной темой приложения.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme:
          brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
}
