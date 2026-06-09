/// Назначение: наблюдение сессии Supabase для навигации и обновления роутера.
///
/// Слой: core/auth
/// Зависимости: supabase_flutter, flutter_riverpod,
///   core/supabase/supabase_providers.dart.
/// Ключевые типы: authStateChangesProvider, currentSessionProvider,
///   GoRouterRefreshStream.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';

/// Стрим изменений состояния авторизации Supabase.
final authStateChangesProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseClientProvider).auth.onAuthStateChange,
);

/// Текущая сессия (или `null`). Источник истины — Supabase.
final currentSessionProvider = Provider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final state = ref.watch(authStateChangesProvider);
  return state.valueOrNull?.session ?? client.auth.currentSession;
});

/// Адаптер `Stream` → `Listenable` для `GoRouter.refreshListenable`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
