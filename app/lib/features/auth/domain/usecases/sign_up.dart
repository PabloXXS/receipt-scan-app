/// Назначение: сценарий регистрации по email, паролю и стране.
///
/// Слой: domain
/// Фича: auth
/// Зависимости: domain/repositories/auth_repository.dart.
/// Ключевые типы: SignUp.
library;

import '../repositories/auth_repository.dart';

/// Регистрация нового пользователя.
class SignUp {
  const SignUp(this._repo);
  final AuthRepository _repo;

  Future<void> call({
    required String email,
    required String password,
    required String countryCode,
  }) =>
      _repo.signUp(email: email, password: password, countryCode: countryCode);
}
