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

/// Базовая ошибка сканирования чека (пользователю показывается `message`).
sealed class ScanFailure extends Failure {
  const ScanFailure(super.message);
}

/// Нет доступа к камере или галерее.
class CameraPermissionDeniedFailure extends ScanFailure {
  const CameraPermissionDeniedFailure([
    super.message =
        'Нет доступа к камере или галерее. Разрешите его в настройках.',
  ]);
}

/// Не удалось загрузить фото или создать чек.
class UploadFailure extends ScanFailure {
  const UploadFailure([
    super.message = 'Не удалось отправить чек. Попробуйте ещё раз.',
  ]);
}

/// Нет соединения с сервером при сканировании.
class ScanNetworkFailure extends ScanFailure {
  const ScanNetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Непредвиденная ошибка сканирования.
class UnknownScanFailure extends ScanFailure {
  const UnknownScanFailure([super.message = 'Не удалось обработать чек']);
}

/// Базовая ошибка работы со списком/деталями чеков (показывается `message`).
sealed class ReceiptsFailure extends Failure {
  const ReceiptsFailure(super.message);
}

/// Нет соединения с сервером при загрузке чеков.
class ReceiptsNetworkFailure extends ReceiptsFailure {
  const ReceiptsNetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Не удалось загрузить чеки.
class ReceiptsLoadFailure extends ReceiptsFailure {
  const ReceiptsLoadFailure([
    super.message = 'Не удалось загрузить чеки. Попробуйте ещё раз.',
  ]);
}

/// Не удалось удалить чек.
class ReceiptsDeleteFailure extends ReceiptsFailure {
  const ReceiptsDeleteFailure([
    super.message = 'Не удалось удалить чек. Попробуйте ещё раз.',
  ]);
}

/// Непредвиденная ошибка при работе с чеками.
class UnknownReceiptsFailure extends ReceiptsFailure {
  const UnknownReceiptsFailure(
      [super.message = 'Не удалось обработать запрос']);
}

/// Базовая ошибка работы с профилем (показывается `message`).
sealed class ProfileFailure extends Failure {
  const ProfileFailure(super.message);
}

/// Нет соединения с сервером при работе с профилем.
class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Не удалось загрузить профиль.
class ProfileLoadFailure extends ProfileFailure {
  const ProfileLoadFailure([
    super.message = 'Не удалось загрузить профиль. Попробуйте ещё раз.',
  ]);
}

/// Не удалось сохранить профиль.
class ProfileSaveFailure extends ProfileFailure {
  const ProfileSaveFailure([
    super.message = 'Не удалось сохранить изменения. Попробуйте ещё раз.',
  ]);
}

/// Не удалось загрузить аватар.
class ProfileAvatarFailure extends ProfileFailure {
  const ProfileAvatarFailure([
    super.message = 'Не удалось обновить аватар. Попробуйте ещё раз.',
  ]);
}

/// Непредвиденная ошибка при работе с профилем.
class UnknownProfileFailure extends ProfileFailure {
  const UnknownProfileFailure([super.message = 'Не удалось обработать запрос']);
}
