/// Назначение: сценарий входа по email и паролю.
///
/// Слой: domain
/// Фича: auth
/// Зависимости: domain/repositories/auth_repository.dart.
/// Ключевые типы: SignIn.
library;

import '../repositories/auth_repository.dart';

/// Вход по email и паролю.
class SignIn {
  const SignIn(this._repo);
  final AuthRepository _repo;

  Future<void> call({required String email, required String password}) =>
      _repo.signIn(email: email, password: password);
}
