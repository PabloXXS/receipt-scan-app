/// Назначение: общие флаги и константы приложения.
///
/// Слой: core/config
/// Зависимости: нет.
/// Ключевые типы: AppConfig.
library;

/// Глобальные настройки приложения (нечувствительные значения).
class AppConfig {
  const AppConfig();

  /// Базовая локаль по умолчанию.
  static const String defaultLocale = 'ru';

  /// Deep-link для возврата из писем подтверждения/сброса пароля.
  static const String authRedirectUrl = 'chekiprices://login-callback';
}
