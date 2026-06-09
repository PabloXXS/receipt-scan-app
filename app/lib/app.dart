/// Назначение: корневой виджет — MaterialApp.router, тема, навигация.
///
/// Слой: presentation (корень)
/// Зависимости: core/router, core/auth, core/theme, flutter_riverpod, supabase_flutter.
/// Ключевые типы: ChekiPricesApp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_providers.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Корневой виджет приложения.
class ChekiPricesApp extends ConsumerWidget {
  const ChekiPricesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // При входе по recovery-ссылке Supabase эмитит passwordRecovery —
    // уводим пользователя на экран установки нового пароля.
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        router.go(AppRoutes.resetPassword);
      }
    });

    return MaterialApp.router(
      title: 'ChekiPrices',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
