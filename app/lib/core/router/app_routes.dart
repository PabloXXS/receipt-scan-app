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

  // Вкладки нижнего меню.
  static const String receipts = '/receipts';
  static const String statistics = '/statistics';
  static const String scan = '/scan';
  static const String profile = '/profile';

  /// Шаблон маршрута деталей чека (вложен в ветку receipts).
  static const String receiptDetail = '/receipts/:id';

  /// Путь к деталям конкретного чека.
  static String receiptDetailPath(String id) => '/receipts/$id';
}
