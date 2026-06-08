/// Назначение: конфигурация навигации (GoRouter) с redirect по auth-состоянию.
///
/// Слой: core/router
/// Зависимости: go_router, flutter_riverpod.
/// Ключевые типы: appRouterProvider.
/// Заглушка: маршруты фич добавляются по мере реализации.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Провайдер корневого роутера приложения.
///
/// TODO(feature): подключить redirect по `authStateChanges` и маршруты фич.
final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  ),
);
