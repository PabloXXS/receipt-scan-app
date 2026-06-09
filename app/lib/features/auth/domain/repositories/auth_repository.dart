/// Назначение: контракт авторизации (действия над сессией пользователя).
///
/// Слой: domain
/// Фича: auth
/// Зависимости: нет (бросает core/error/failure.dart::AuthFailure).
/// Ключевые типы: AuthRepository.
library;

/// Действия авторизации. Методы бросают `AuthFailure` при ошибке.
abstract interface class AuthRepository {
  /// Вход по email и паролю.
  Future<void> signIn({required String email, required String password});

  /// Регистрация; `countryCode` уходит в user_metadata (для триггера профиля).
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  });

  /// Выход из текущей сессии.
  Future<void> signOut();

  /// Отправка письма со ссылкой для сброса пароля.
  Future<void> requestPasswordReset(String email);

  /// Установка нового пароля (в активной recovery-сессии).
  Future<void> resetPassword(String newPassword);
}
