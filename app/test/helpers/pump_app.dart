/// Назначение: хелпер widget-тестов — ProviderScope + MaterialApp с темой.
///
/// Слой: test/helpers
/// Зависимости: flutter_test, flutter_riverpod, core/theme/app_theme.dart.
/// Ключевые типы: pumpApp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_theme.dart';

/// Рендерит [child] внутри ProviderScope и MaterialApp.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
}
