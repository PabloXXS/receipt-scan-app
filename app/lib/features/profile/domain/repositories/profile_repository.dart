/// Назначение: абстракция доступа к данным профиля.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: dart:typed_data, domain/entities/profile.dart.
/// Ключевые типы: ProfileRepository.
library;

import 'dart:typed_data';

import '../entities/profile.dart';

/// Контракт репозитория профиля.
abstract interface class ProfileRepository {
  /// Профиль текущего пользователя.
  Future<Profile> getCurrent();

  /// Обновляет отображаемое имя, возвращает обновлённый профиль.
  Future<Profile> updateName(String displayName);

  /// Меняет страну (country_code), возвращает обновлённый профиль.
  Future<Profile> setCountry(String countryCode);

  /// Загружает аватар (готовые jpeg-байты), возвращает профиль с avatar_url.
  Future<Profile> updateAvatar(Uint8List bytes);

  /// Удаляет аватар, возвращает профиль без avatar_url.
  Future<Profile> removeAvatar();
}
