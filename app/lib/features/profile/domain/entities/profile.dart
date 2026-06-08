/// Назначение: доменная сущность профиля пользователя.
///
/// Слой: domain
/// Фича: profile
/// Зависимости: нет.
/// Ключевые типы: Profile.
/// Заглушка: поля и логика добавляются в итерации фичи profile.
library;

/// Профиль пользователя (страна, имя, привязка к семье).
class Profile {
  const Profile({
    required this.id,
    required this.countryCode,
    this.displayName,
    this.familyId,
  });

  /// Идентификатор пользователя (= auth.uid).
  final String id;

  /// Код страны (мапер к фискальному провайдеру).
  final String countryCode;

  /// Отображаемое имя.
  final String? displayName;

  /// Идентификатор семьи (если состоит в семье).
  final String? familyId;
}
