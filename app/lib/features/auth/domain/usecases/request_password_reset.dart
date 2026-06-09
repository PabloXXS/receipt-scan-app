/// Назначение: сценарий запроса письма для сброса пароля.
///
/// Слой: domain
/// Фича: auth
/// Зависимости: domain/repositories/auth_repository.dart.
/// Ключевые типы: RequestPasswordReset.
library;

import '../repositories/auth_repository.dart';

/// Запрос письма со ссылкой для сброса пароля.
class RequestPasswordReset {
  const RequestPasswordReset(this._repo);
  final AuthRepository _repo;

  Future<void> call(String email) => _repo.requestPasswordReset(email);
}
