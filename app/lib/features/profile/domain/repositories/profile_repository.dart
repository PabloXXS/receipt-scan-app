/// Назначение: абстракция доступа к данным профиля.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: domain/entities/profile.dart.
/// Ключевые типы: ProfileRepository.
/// Заглушка: реализация — в data-слое в итерации фичи profile.
library;

import '../entities/profile.dart';

/// Контракт репозитория профиля.
abstract interface class ProfileRepository {
  /// Возвращает профиль текущего пользователя.
  Future<Profile> getCurrent();

  /// Сохраняет изменённый профиль.
  Future<void> update(Profile profile);
}
