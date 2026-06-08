/// Назначение: конфигурация подключения к Supabase (URL и anon-ключ).
///
/// Слой: core/config
/// Зависимости: значения из --dart-define окружения.
/// Ключевые типы: SupabaseConfig.
library;

/// Параметры подключения к Supabase, читаемые из окружения сборки.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.anonKey});

  /// URL проекта Supabase (`--dart-define=SUPABASE_URL=...`).
  final String url;

  /// Публичный anon-ключ (`--dart-define=SUPABASE_ANON_KEY=...`).
  final String anonKey;

  /// Читает конфигурацию из `--dart-define` значений сборки.
  factory SupabaseConfig.fromEnv() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        anonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      );
}
