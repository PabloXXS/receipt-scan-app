/// Назначение: корневой виджет — MaterialApp.router, тема, навигация.
///
/// Слой: presentation (корень)
/// Зависимости: core/router, core/theme, flutter_riverpod.
/// Ключевые типы: ChekiPricesApp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Корневой виджет приложения.
class ChekiPricesApp extends ConsumerWidget {
  const ChekiPricesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ChekiPrices',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
