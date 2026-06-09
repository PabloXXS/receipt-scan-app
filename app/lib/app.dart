/// Назначение: корневой виджет — MaterialApp.router, тема, навигация.
///
/// Слой: presentation (корень)
/// Зависимости: core/router, core/auth, core/theme, flutter_riverpod, supabase_flutter.
/// Ключевые типы: ChekiPricesApp.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_providers.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';

/// Корневой виджет приложения.
class ChekiPricesApp extends ConsumerStatefulWidget {
  const ChekiPricesApp({super.key});

  @override
  ConsumerState<ChekiPricesApp> createState() => _ChekiPricesAppState();
}

class _ChekiPricesAppState extends ConsumerState<ChekiPricesApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = ref.read(appRouterProvider);

    // При входе по recovery-ссылке Supabase эмитит passwordRecovery —
    // уводим пользователя на экран установки нового пароля. Слушатель
    // регистрируется один раз при монтировании (надёжнее, чем в build).
    ref.listenManual(authStateChangesProvider, (previous, next) {
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        _router.go(AppRoutes.resetPassword);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChekiPrices',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
