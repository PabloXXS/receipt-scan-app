/// Назначение: предоставляет инициализированный SupabaseClient как Riverpod-провайдер.
///
/// Слой: core/supabase
/// Зависимости: supabase_flutter, flutter_riverpod.
/// Ключевые типы: supabaseClientProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Глобальный клиент Supabase (инициализируется в `main.dart`).
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
