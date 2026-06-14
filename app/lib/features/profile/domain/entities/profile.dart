/// Назначение: доменная сущность профиля пользователя.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: нет.
/// Ключевые типы: Profile.
library;

/// Профиль пользователя (страна, имя, аватар, привязка к семье).
class Profile {
  const Profile({
    required this.id,
    required this.countryCode,
    this.displayName,
    this.avatarUrl,
    this.familyId,
  });

  /// Идентификатор пользователя (= auth.uid).
  final String id;

  /// Код страны (мапер к фискальному провайдеру).
  final String countryCode;

  /// Отображаемое имя.
  final String? displayName;

  /// Публичный URL аватара (или null).
  final String? avatarUrl;

  /// Идентификатор семьи (если состоит в семье).
  final String? familyId;

  /// Копия с заменой полей. `clearAvatar: true` сбрасывает [avatarUrl] в null.
  Profile copyWith({
    String? countryCode,
    String? displayName,
    String? avatarUrl,
    String? familyId,
    bool clearAvatar = false,
  }) {
    return Profile(
      id: id,
      countryCode: countryCode ?? this.countryCode,
      displayName: displayName ?? this.displayName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      familyId: familyId ?? this.familyId,
    );
  }
}
