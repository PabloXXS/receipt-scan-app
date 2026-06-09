/// Назначение: чистая политика перенаправления по состоянию авторизации.
///
/// Слой: core/router
/// Зависимости: core/router/app_routes.dart.
/// Ключевые типы: authRedirect.
library;

import 'app_routes.dart';

const Set<String> _publicRoutes = {
  AppRoutes.signIn,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
  AppRoutes.checkEmail,
};

/// Возвращает путь для перенаправления или `null`, если редирект не нужен.
///
/// Правила: неавторизованный пускается только на публичные auth-маршруты;
/// авторизованный с публичного auth-маршрута или `home` уводится на первую
/// вкладку (`receipts`), кроме `resetPassword` (доступен по recovery-сессии).
String? authRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  final onPublic = _publicRoutes.contains(location);
  final onReset = location == AppRoutes.resetPassword;

  if (!isAuthenticated) {
    return onPublic ? null : AppRoutes.signIn;
  }
  if (onReset) return null;
  if (onPublic || location == AppRoutes.home) return AppRoutes.receipts;
  return null;
}
