/// Назначение: сценарий выхода из сессии.
///
/// Слой: domain
/// Фича: auth
/// Зависимости: domain/repositories/auth_repository.dart.
/// Ключевые типы: SignOut.
library;

import '../repositories/auth_repository.dart';

/// Выход из текущей сессии.
class SignOut {
  const SignOut(this._repo);
  final AuthRepository _repo;

  Future<void> call() => _repo.signOut();
}
