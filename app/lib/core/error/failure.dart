/// Назначение: базовый тип ошибок домена и маппинг исключений.
///
/// Слой: core/error
/// Зависимости: нет.
/// Ключевые типы: Failure.
library;

/// Базовая ошибка прикладного уровня.
sealed class Failure {
  const Failure(this.message);

  /// Человекочитаемое сообщение об ошибке.
  final String message;
}

/// Непредвиденная ошибка.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Unexpected error']);
}

/// Базовая ошибка авторизации (пользователю показывается `message`).
sealed class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Неверный email или пароль.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure(
      [super.message = 'Неверный email или пароль']);
}

/// Email не подтверждён.
class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure([
    super.message = 'Подтвердите email по ссылке из письма',
  ]);
}

/// Email уже зарегистрирован.
class EmailAlreadyRegisteredFailure extends AuthFailure {
  const EmailAlreadyRegisteredFailure([
    super.message = 'Этот email уже зарегистрирован',
  ]);
}

/// Слишком простой пароль.
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([super.message = 'Пароль слишком простой']);
}

/// Превышен лимит отправки писем/запросов.
class RateLimitFailure extends AuthFailure {
  const RateLimitFailure([
    super.message = 'Слишком много запросов, попробуйте позже',
  ]);
}

/// Нет соединения с сервером.
class NetworkFailure extends AuthFailure {
  const NetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Непредвиденная ошибка авторизации.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([super.message = 'Не удалось выполнить операцию']);
}
