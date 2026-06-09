/// Назначение: константы путей навигации (без зависимости от виджетов).
///
/// Слой: core/router
/// Зависимости: нет.
/// Ключевые типы: AppRoutes.
library;

/// Пути маршрутов приложения.
abstract final class AppRoutes {
  static const String home = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/check-email';
  static const String resetPassword = '/reset-password';
}
