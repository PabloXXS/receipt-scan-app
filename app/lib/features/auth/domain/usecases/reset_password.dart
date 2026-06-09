/// Назначение: сценарий установки нового пароля (recovery-сессия).
///
/// Слой: domain
/// Фича: auth
/// Зависимости: domain/repositories/auth_repository.dart.
/// Ключевые типы: ResetPassword.
library;

import '../repositories/auth_repository.dart';

/// Установка нового пароля в активной recovery-сессии.
class ResetPassword {
  const ResetPassword(this._repo);
  final AuthRepository _repo;

  Future<void> call(String newPassword) => _repo.resetPassword(newPassword);
}
