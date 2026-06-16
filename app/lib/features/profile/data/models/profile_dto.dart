/// Назначение: маппинг строки PostgREST `profiles` в доменный Profile.
///
/// Слой: data
/// Фича: profile
/// Зависимости: domain/entities/profile.dart.
/// Ключевые типы: profileFromRow, kProfileColumns.
library;

import '../../domain/entities/profile.dart';

/// Колонки профиля для select.
const String kProfileColumns =
    'id, country_code, display_name, avatar_url, family_id';

/// Строка `profiles` → [Profile].
Profile profileFromRow(Map<String, dynamic> row) => Profile(
      id: row['id'] as String,
      countryCode: row['country_code'] as String,
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      familyId: row['family_id'] as String?,
    );
