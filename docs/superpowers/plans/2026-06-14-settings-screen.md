# Экран «Настройки» — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Превратить экран-заглушку профиля в экран «Настройки»: профиль (аватар/имя/email), редактирование имени и аватара, показ/смена страны, переключение темы, смена пароля, плитка «Семья» (disabled), выход.

**Architecture:** Feature-first (`features/profile/{data,domain,presentation}`), зависимости внутрь. DI через Riverpod (`SupabaseClient → datasource → repository → controller`). Контроллеры — codegen `@riverpod`. Тема хранится локально в `shared_preferences` через провайдер в `core/`. Аватар — в Storage-бакете `avatars`, ссылка в `profiles.avatar_url`.

**Tech Stack:** Flutter, Riverpod (codegen), GoRouter, Supabase (Postgres + Storage), `image_picker`, `image`, `shared_preferences`. Пакет проекта: `ticket_app`.

**Спека:** `docs/superpowers/specs/2026-06-14-settings-screen-design.md`

**Конвенции:** каждый новый `.dart` — с dartdoc-шапкой (`docs/conventions/documentation.md`). UI-примитивы только из каталога `lib/shared/components/`. Без `Colors.*`, сырых `TextStyle`, магических отступов — только `context.tokens`/`colorScheme`/`textTheme`. После codegen-задач: `dart run build_runner build --delete-conflicting-outputs`. Гейты на каждом коммите: `dart analyze` (без ошибок) и `flutter test`.

---

## Файловая структура

Новые файлы:
- `supabase/migrations/<ts>_profile_avatar.sql` — колонка + бакет + RLS.
- `app/lib/core/constants/supported_countries.dart` — единый каталог стран.
- `app/lib/core/storage/preferences_providers.dart` — `sharedPreferencesProvider`.
- `app/lib/core/theme/theme_mode_controller.dart` (+ `.g.dart`) — выбор темы.
- `app/lib/features/profile/data/models/profile_dto.dart`
- `app/lib/features/profile/data/profile_error_mapper.dart`
- `app/lib/features/profile/data/datasources/profile_remote_datasource.dart`
- `app/lib/features/profile/data/repositories/profile_repository_impl.dart`
- `app/lib/features/profile/data/avatar_image_processor.dart` — кроп/даунскейл.
- `app/lib/features/profile/presentation/controllers/profile_controller.dart` (+ `.g.dart`)
- `app/lib/features/profile/presentation/screens/settings_screen.dart` (взамен `profile_screen.dart`)
- `app/lib/features/profile/presentation/screens/edit_profile_screen.dart`
- `app/lib/features/profile/presentation/widgets/profile_header.dart`
- `app/lib/features/profile/presentation/widgets/country_picker_sheet.dart`
- `app/lib/features/profile/presentation/widgets/theme_mode_sheet.dart`
- `app/test/features/profile/profile_test_fakes.dart`
- `app/test/features/profile/data/models/profile_dto_test.dart`
- `app/test/features/profile/data/repositories/profile_repository_impl_test.dart`
- `app/test/features/profile/presentation/controllers/profile_controller_test.dart`
- `app/test/core/theme/theme_mode_controller_test.dart`

Изменяемые:
- `app/lib/core/error/failure.dart` (+ `ProfileFailure`)
- `app/lib/core/auth/auth_providers.dart` (+ `currentUserEmailProvider`)
- `app/lib/features/profile/domain/entities/profile.dart` (+ `avatarUrl`, `copyWith`)
- `app/lib/features/profile/domain/repositories/profile_repository.dart` (новый контракт)
- `app/lib/features/auth/presentation/widgets/country_field.dart` (импорт каталога стран)
- `app/lib/main.dart` (init prefs + override)
- `app/lib/app.dart` (`themeMode` из провайдера)
- `app/lib/core/router/app_routes.dart`, `app_router.dart` (роут `/profile/edit`, экран Settings)
- `docs/features/profile.md`, `docs/architecture/data-model.md`

Удаляемые:
- `app/lib/features/profile/presentation/screens/profile_screen.dart`

---

## Task 1: Миграция БД — колонка avatar_url, бакет avatars, RLS

**Files:**
- Create: `supabase/migrations/<timestamp>_profile_avatar.sql`
- Modify: `docs/architecture/data-model.md`

- [ ] **Step 1: Найти каталог миграций и формат имени**

Run: `ls supabase/migrations | tail -5`
Посмотреть формат timestamp у последней миграции и использовать тот же (`YYYYMMDDHHMMSS_*.sql`). Имя: `<timestamp>_profile_avatar.sql`.

- [ ] **Step 2: Написать миграцию**

```sql
-- Профиль: аватар пользователя (зона A). Storage-бакет avatars + RLS.

alter table public.profiles
  add column if not exists avatar_url text;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

-- Публичное чтение объектов бакета avatars.
create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

-- Запись/обновление/удаление — только в свою папку {auth.uid}/...
create policy "avatars_insert_own"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_update_own"
on storage.objects for update to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_delete_own"
on storage.objects for delete to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);
```

- [ ] **Step 3: Применить миграцию в dev-проект**

Применить через Supabase MCP `apply_migration` (проект CheckPrices `yftrsgcqrzzmxbttlltz`) либо `supabase db push`, как принято в проекте. Проверить успешность.

- [ ] **Step 4: Проверка приватности субагентом**

Запустить субагент `privacy-rls-reviewer` на миграцию: подтвердить, что изменения — зона A (per-user), зоны цен (`prices`/`price_aggregates`) не затронуты, RLS Storage ограничивает запись своей папкой. Исправить замечания, если есть.

- [ ] **Step 5: Обновить data-model.md**

В строку таблицы `profiles` добавить `avatar_url` и упоминание бакета `avatars` (зона A, RLS по `auth.uid`).

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations docs/architecture/data-model.md
git commit -m "feat(profile): миграция avatar_url + бакет avatars с RLS"
```

---

## Task 2: Единый каталог стран в core

**Files:**
- Create: `app/lib/core/constants/supported_countries.dart`
- Modify: `app/lib/features/auth/presentation/widgets/country_field.dart`

- [ ] **Step 1: Создать каталог стран**

```dart
/// Назначение: единый справочник поддерживаемых стран (код → название).
///
/// Слой: core/constants
/// Зависимости: нет.
/// Ключевые типы: kSupportedCountries.
library;

/// Поддерживаемые страны (код → название). v1: СНГ.
const Map<String, String> kSupportedCountries = {
  'BY': 'Беларусь',
  'RU': 'Россия',
  'KZ': 'Казахстан',
};

/// Человекочитаемое название страны по коду (или сам код, если не найдено).
String countryName(String? code) =>
    code == null ? '—' : (kSupportedCountries[code] ?? code);
```

- [ ] **Step 2: Переключить country_field.dart на каталог**

Удалить локальную константу `kSupportedCountries` из `country_field.dart`, добавить импорт `import '../../../../core/constants/supported_countries.dart';`. Тело виджета не меняется.

- [ ] **Step 3: Проверка**

Run: `cd app && dart analyze lib/features/auth lib/core/constants`
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/constants/supported_countries.dart app/lib/features/auth/presentation/widgets/country_field.dart
git commit -m "refactor(core): единый каталог стран kSupportedCountries"
```

---

## Task 3: Domain — Profile.avatarUrl, copyWith, контракт репозитория, ProfileFailure

**Files:**
- Modify: `app/lib/features/profile/domain/entities/profile.dart`
- Modify: `app/lib/features/profile/domain/repositories/profile_repository.dart`
- Modify: `app/lib/core/error/failure.dart`
- Test: `app/test/features/profile/domain/entities/profile_test.dart`

- [ ] **Step 1: Написать тест copyWith**

Create `app/test/features/profile/domain/entities/profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/domain/entities/profile.dart';

void main() {
  const base = Profile(id: 'u1', countryCode: 'RU', displayName: 'Аня');

  test('copyWith меняет только переданные поля', () {
    final next = base.copyWith(displayName: 'Боря');
    expect(next.id, 'u1');
    expect(next.countryCode, 'RU');
    expect(next.displayName, 'Боря');
    expect(next.avatarUrl, isNull);
  });

  test('copyWith с clearAvatar сбрасывает avatarUrl', () {
    const withAvatar = Profile(
      id: 'u1',
      countryCode: 'RU',
      avatarUrl: 'https://x/a.jpg',
    );
    final next = withAvatar.copyWith(clearAvatar: true);
    expect(next.avatarUrl, isNull);
  });
}
```

- [ ] **Step 2: Запустить — упадёт (нет avatarUrl/copyWith)**

Run: `cd app && flutter test test/features/profile/domain/entities/profile_test.dart`
Expected: FAIL (compile error: no `avatarUrl`/`copyWith`).

- [ ] **Step 3: Обновить сущность Profile**

Заменить тело `app/lib/features/profile/domain/entities/profile.dart`:

```dart
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
```

- [ ] **Step 4: Запустить тест — пройдёт**

Run: `cd app && flutter test test/features/profile/domain/entities/profile_test.dart`
Expected: PASS.

- [ ] **Step 5: Обновить контракт репозитория**

Заменить тело `app/lib/features/profile/domain/repositories/profile_repository.dart`:

```dart
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
```

- [ ] **Step 6: Добавить ProfileFailure в core/error/failure.dart**

В конец `app/lib/core/error/failure.dart` добавить:

```dart
/// Базовая ошибка работы с профилем (показывается `message`).
sealed class ProfileFailure extends Failure {
  const ProfileFailure(super.message);
}

/// Нет соединения с сервером при работе с профилем.
class ProfileNetworkFailure extends ProfileFailure {
  const ProfileNetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Не удалось загрузить профиль.
class ProfileLoadFailure extends ProfileFailure {
  const ProfileLoadFailure([
    super.message = 'Не удалось загрузить профиль. Попробуйте ещё раз.',
  ]);
}

/// Не удалось сохранить профиль.
class ProfileSaveFailure extends ProfileFailure {
  const ProfileSaveFailure([
    super.message = 'Не удалось сохранить изменения. Попробуйте ещё раз.',
  ]);
}

/// Не удалось загрузить аватар.
class ProfileAvatarFailure extends ProfileFailure {
  const ProfileAvatarFailure([
    super.message = 'Не удалось обновить аватар. Попробуйте ещё раз.',
  ]);
}

/// Непредвиденная ошибка при работе с профилем.
class UnknownProfileFailure extends ProfileFailure {
  const UnknownProfileFailure([super.message = 'Не удалось обработать запрос']);
}
```

- [ ] **Step 7: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile/domain lib/core/error && flutter test test/features/profile/domain`
Expected: No issues; PASS.

```bash
git add app/lib/features/profile/domain app/lib/core/error/failure.dart app/test/features/profile/domain
git commit -m "feat(profile): доменный контракт профиля (avatar, copyWith) + ProfileFailure"
```

---

## Task 4: Data — DTO + error mapper (TDD)

**Files:**
- Create: `app/lib/features/profile/data/models/profile_dto.dart`
- Create: `app/lib/features/profile/data/profile_error_mapper.dart`
- Test: `app/test/features/profile/data/models/profile_dto_test.dart`

- [ ] **Step 1: Тест DTO**

Create `app/test/features/profile/data/models/profile_dto_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/data/models/profile_dto.dart';

void main() {
  test('profileFromRow маппит все поля', () {
    final p = profileFromRow({
      'id': 'u1',
      'country_code': 'BY',
      'display_name': 'Аня',
      'avatar_url': 'https://x/a.jpg',
      'family_id': 'f1',
    });
    expect(p.id, 'u1');
    expect(p.countryCode, 'BY');
    expect(p.displayName, 'Аня');
    expect(p.avatarUrl, 'https://x/a.jpg');
    expect(p.familyId, 'f1');
  });

  test('profileFromRow допускает null-поля', () {
    final p = profileFromRow({'id': 'u1', 'country_code': 'RU'});
    expect(p.displayName, isNull);
    expect(p.avatarUrl, isNull);
    expect(p.familyId, isNull);
  });
}
```

- [ ] **Step 2: Запустить — упадёт**

Run: `cd app && flutter test test/features/profile/data/models/profile_dto_test.dart`
Expected: FAIL (нет `profile_dto.dart`).

- [ ] **Step 3: Реализовать DTO**

Create `app/lib/features/profile/data/models/profile_dto.dart`:

```dart
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
```

- [ ] **Step 4: Запустить — пройдёт**

Run: `cd app && flutter test test/features/profile/data/models/profile_dto_test.dart`
Expected: PASS.

- [ ] **Step 5: Реализовать error mapper**

Create `app/lib/features/profile/data/profile_error_mapper.dart`:

```dart
/// Назначение: перевод исключений Supabase/сети в ProfileFailure.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:io, supabase_flutter, core/error/failure.dart.
/// Ключевые типы: mapProfileException.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] в [ProfileFailure]. Готовый [ProfileFailure] — как есть.
ProfileFailure mapProfileException(Object error) {
  if (error is ProfileFailure) return error;
  if (error is SocketException) return const ProfileNetworkFailure();
  if (error is StorageException) return const ProfileAvatarFailure();
  if (error is PostgrestException) return const ProfileLoadFailure();
  return const UnknownProfileFailure();
}
```

- [ ] **Step 6: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile/data && flutter test test/features/profile/data`
Expected: No issues; PASS.

```bash
git add app/lib/features/profile/data/models app/lib/features/profile/data/profile_error_mapper.dart app/test/features/profile/data/models
git commit -m "feat(profile): DTO-маппинг profiles + ProfileFailure-маппер"
```

---

## Task 5: Data — обработка изображения аватара (TDD)

**Files:**
- Create: `app/lib/features/profile/data/avatar_image_processor.dart`
- Test: `app/test/features/profile/data/avatar_image_processor_test.dart`

- [ ] **Step 1: Тест процессора**

Create `app/test/features/profile/data/avatar_image_processor_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_app/features/profile/data/avatar_image_processor.dart';

void main() {
  test('кропит до квадрата и ужимает до <= 512px', () {
    // Прямоугольник 800x400.
    final src = img.Image(width: 800, height: 400);
    final bytes = img.encodeJpg(src);

    final out = processAvatar(bytes);
    final decoded = img.decodeImage(out)!;

    expect(decoded.width, decoded.height); // квадрат
    expect(decoded.width, lessThanOrEqualTo(512));
  });
}
```

- [ ] **Step 2: Запустить — упадёт**

Run: `cd app && flutter test test/features/profile/data/avatar_image_processor_test.dart`
Expected: FAIL (нет `avatar_image_processor.dart`).

- [ ] **Step 3: Реализовать процессор**

Create `app/lib/features/profile/data/avatar_image_processor.dart`:

```dart
/// Назначение: подготовка изображения аватара (центр-кроп в квадрат, даунскейл, JPEG).
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, package:image.
/// Ключевые типы: processAvatar, kAvatarMaxSide.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Максимальная сторона аватара в пикселях.
const int kAvatarMaxSide = 512;

/// Декодирует [input], делает центр-квадрат-кроп, ужимает до [kAvatarMaxSide]
/// и кодирует в JPEG (q=85). Бросает [FormatException], если не изображение.
Uint8List processAvatar(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать изображение');
  }
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cropped = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = side > kAvatarMaxSide
      ? img.copyResize(cropped, width: kAvatarMaxSide, height: kAvatarMaxSide)
      : cropped;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
```

- [ ] **Step 4: Запустить — пройдёт**

Run: `cd app && flutter test test/features/profile/data/avatar_image_processor_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/profile/data/avatar_image_processor.dart app/test/features/profile/data/avatar_image_processor_test.dart
git commit -m "feat(profile): кроп/даунскейл аватара (package:image)"
```

---

## Task 6: Data — datasource + repository impl + DI (TDD на репозитории)

**Files:**
- Create: `app/lib/features/profile/data/datasources/profile_remote_datasource.dart`
- Create: `app/lib/features/profile/data/repositories/profile_repository_impl.dart`
- Create: `app/test/features/profile/profile_test_fakes.dart`
- Test: `app/test/features/profile/data/repositories/profile_repository_impl_test.dart`

- [ ] **Step 1: Datasource (интерфейс + Supabase-реализация)**

Create `app/lib/features/profile/data/datasources/profile_remote_datasource.dart`:

```dart
/// Назначение: доступ к строке profiles и Storage-бакету avatars.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, flutter_riverpod, supabase_flutter,
///   core/supabase/supabase_providers.dart, models/profile_dto.dart, domain/entities.
/// Ключевые типы: ProfileRemoteDataSource, SupabaseProfileRemoteDataSource,
///   profileRemoteDataSourceProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/profile.dart';
import '../models/profile_dto.dart';

/// Удалённые операции с профилем и аватаром.
abstract interface class ProfileRemoteDataSource {
  Future<Profile> fetchCurrent();
  Future<Profile> updateName(String displayName);
  Future<Profile> setCountry(String countryCode);
  Future<Profile> uploadAvatar(Uint8List bytes);
  Future<Profile> removeAvatar();
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseProfileRemoteDataSource implements ProfileRemoteDataSource {
  const SupabaseProfileRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'avatars';

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Profile> fetchCurrent() async {
    final row = await _client
        .from('profiles')
        .select(kProfileColumns)
        .eq('id', _uid)
        .single();
    return profileFromRow(row);
  }

  Future<Profile> _patch(Map<String, dynamic> values) async {
    final row = await _client
        .from('profiles')
        .update(values)
        .eq('id', _uid)
        .select(kProfileColumns)
        .single();
    return profileFromRow(row);
  }

  @override
  Future<Profile> updateName(String displayName) =>
      _patch({'display_name': displayName});

  @override
  Future<Profile> setCountry(String countryCode) =>
      _patch({'country_code': countryCode});

  @override
  Future<Profile> uploadAvatar(Uint8List bytes) async {
    final path = '$_uid/avatar.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    final base = _client.storage.from(_bucket).getPublicUrl(path);
    // Cache-bust, чтобы UI подхватил новый файл по тому же пути.
    final url = '$base?v=${DateTime.now().millisecondsSinceEpoch}';
    return _patch({'avatar_url': url});
  }

  @override
  Future<Profile> removeAvatar() async {
    await _client.storage.from(_bucket).remove(['$_uid/avatar.jpg']);
    return _patch({'avatar_url': null});
  }
}

/// DI-провайдер источника данных профиля.
final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => SupabaseProfileRemoteDataSource(ref.watch(supabaseClientProvider)),
);
```

- [ ] **Step 2: Фейки для тестов**

Create `app/test/features/profile/profile_test_fakes.dart`:

```dart
import 'dart:typed_data';

import 'package:ticket_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:ticket_app/features/profile/domain/entities/profile.dart';
import 'package:ticket_app/features/profile/domain/repositories/profile_repository.dart';

/// Профиль для тестов.
Profile makeProfile({
  String id = 'u1',
  String countryCode = 'RU',
  String? displayName = 'Аня',
  String? avatarUrl,
}) =>
    Profile(
      id: id,
      countryCode: countryCode,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );

/// Фейк datasource: хранит профиль в памяти, опционально кидает [error].
class FakeProfileRemoteDataSource implements ProfileRemoteDataSource {
  FakeProfileRemoteDataSource(this.profile);
  Profile profile;
  Object? error;

  @override
  Future<Profile> fetchCurrent() async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<Profile> updateName(String displayName) async {
    if (error != null) throw error!;
    profile = profile.copyWith(displayName: displayName);
    return profile;
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    if (error != null) throw error!;
    profile = profile.copyWith(countryCode: countryCode);
    return profile;
  }

  @override
  Future<Profile> uploadAvatar(Uint8List bytes) async {
    if (error != null) throw error!;
    profile = profile.copyWith(avatarUrl: 'https://x/a.jpg?v=1');
    return profile;
  }

  @override
  Future<Profile> removeAvatar() async {
    if (error != null) throw error!;
    profile = profile.copyWith(clearAvatar: true);
    return profile;
  }
}

/// Фейк репозитория для тестов контроллеров.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this.profile);
  Profile profile;
  Object? error;

  @override
  Future<Profile> getCurrent() async {
    if (error != null) throw error!;
    return profile;
  }

  @override
  Future<Profile> updateName(String displayName) async {
    if (error != null) throw error!;
    profile = profile.copyWith(displayName: displayName);
    return profile;
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    if (error != null) throw error!;
    profile = profile.copyWith(countryCode: countryCode);
    return profile;
  }

  @override
  Future<Profile> updateAvatar(Uint8List bytes) async {
    if (error != null) throw error!;
    profile = profile.copyWith(avatarUrl: 'https://x/a.jpg?v=1');
    return profile;
  }

  @override
  Future<Profile> removeAvatar() async {
    if (error != null) throw error!;
    profile = profile.copyWith(clearAvatar: true);
    return profile;
  }
}
```

- [ ] **Step 3: Тест репозитория**

Create `app/test/features/profile/data/repositories/profile_repository_impl_test.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/profile/data/repositories/profile_repository_impl.dart';

import '../../profile_test_fakes.dart';

void main() {
  test('getCurrent делегирует datasource', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.getCurrent();
    expect(p.id, 'u1');
  });

  test('updateName сохраняет имя', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.updateName('Боря');
    expect(p.displayName, 'Боря');
  });

  test('сетевая ошибка → ProfileNetworkFailure', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile())
      ..error = const SocketException('no net');
    final repo = ProfileRepositoryImpl(ds);
    expect(repo.getCurrent(), throwsA(isA<ProfileNetworkFailure>()));
  });

  test('updateAvatar возвращает профиль с avatar_url', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.updateAvatar(Uint8List(0));
    expect(p.avatarUrl, isNotNull);
  });
}
```

- [ ] **Step 4: Запустить — упадёт (нет repository impl)**

Run: `cd app && flutter test test/features/profile/data/repositories/profile_repository_impl_test.dart`
Expected: FAIL (нет `profile_repository_impl.dart`).

- [ ] **Step 5: Реализовать репозиторий + DI**

Create `app/lib/features/profile/data/repositories/profile_repository_impl.dart`:

```dart
/// Назначение: реализация ProfileRepository поверх remote datasource.
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, flutter_riverpod,
///   datasources/profile_remote_datasource.dart, profile_error_mapper.dart,
///   domain/repositories/profile_repository.dart.
/// Ключевые типы: ProfileRepositoryImpl, profileRepositoryProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../profile_error_mapper.dart';

/// Делегирует datasource, оборачивает исключения в ProfileFailure.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._ds);

  final ProfileRemoteDataSource _ds;

  @override
  Future<Profile> getCurrent() async {
    try {
      return await _ds.fetchCurrent();
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> updateName(String displayName) async {
    try {
      return await _ds.updateName(displayName);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> setCountry(String countryCode) async {
    try {
      return await _ds.setCountry(countryCode);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> updateAvatar(Uint8List bytes) async {
    try {
      return await _ds.uploadAvatar(bytes);
    } catch (e) {
      throw mapProfileException(e);
    }
  }

  @override
  Future<Profile> removeAvatar() async {
    try {
      return await _ds.removeAvatar();
    } catch (e) {
      throw mapProfileException(e);
    }
  }
}

/// DI-провайдер репозитория профиля.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);
```

- [ ] **Step 6: Запустить — пройдёт**

Run: `cd app && flutter test test/features/profile/data/repositories/profile_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 7: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile/data && flutter test test/features/profile`
Expected: No issues; PASS.

```bash
git add app/lib/features/profile/data app/test/features/profile
git commit -m "feat(profile): Supabase datasource + repository профиля с DI"
```

---

## Task 7: Core — preferences provider + theme mode controller (TDD)

**Files:**
- Create: `app/lib/core/storage/preferences_providers.dart`
- Create: `app/lib/core/theme/theme_mode_controller.dart`
- Modify: `app/lib/main.dart`
- Modify: `app/lib/app.dart`
- Test: `app/test/core/theme/theme_mode_controller_test.dart`

- [ ] **Step 1: Провайдер SharedPreferences**

Create `app/lib/core/storage/preferences_providers.dart`:

```dart
/// Назначение: доступ к SharedPreferences как Riverpod-провайдер.
///
/// Слой: core/storage
/// Зависимости: flutter_riverpod, shared_preferences.
/// Ключевые типы: sharedPreferencesProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экземпляр SharedPreferences. Переопределяется в `main.dart` через override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main()'),
);
```

- [ ] **Step 2: Тест контроллера темы**

Create `app/test/core/theme/theme_mode_controller_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_app/core/storage/preferences_providers.dart';
import 'package:ticket_app/core/theme/theme_mode_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('по умолчанию ThemeMode.system', () async {
    final c = await makeContainer({});
    expect(c.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('читает сохранённое значение', () async {
    final c = await makeContainer({'theme_mode': 'dark'});
    expect(c.read(themeModeControllerProvider), ThemeMode.dark);
  });

  test('setMode обновляет состояние и prefs', () async {
    final c = await makeContainer({});
    await c.read(themeModeControllerProvider.notifier).setMode(ThemeMode.light);
    expect(c.read(themeModeControllerProvider), ThemeMode.light);
  });
}
```

- [ ] **Step 3: Запустить — упадёт**

Run: `cd app && flutter test test/core/theme/theme_mode_controller_test.dart`
Expected: FAIL (нет `theme_mode_controller.dart`).

- [ ] **Step 4: Реализовать контроллер темы**

Create `app/lib/core/theme/theme_mode_controller.dart`:

```dart
/// Назначение: выбор темы оформления (light/dark/system) с хранением в prefs.
///
/// Слой: core/theme
/// Зависимости: flutter material, riverpod_annotation,
///   core/storage/preferences_providers.dart.
/// Ключевые типы: ThemeModeController, themeModeControllerProvider.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/preferences_providers.dart';

part 'theme_mode_controller.g.dart';

const String _kThemeModeKey = 'theme_mode';

/// Текущий [ThemeMode], синхронизирован с SharedPreferences.
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_kThemeModeKey);
    return _decode(raw);
  }

  /// Меняет тему и сохраняет выбор.
  Future<void> setMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_kThemeModeKey, mode.name);
    state = mode;
  }

  ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
```

- [ ] **Step 5: Codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: генерируется `theme_mode_controller.g.dart`, без ошибок.

- [ ] **Step 6: Запустить тест — пройдёт**

Run: `cd app && flutter test test/core/theme/theme_mode_controller_test.dart`
Expected: PASS.

- [ ] **Step 7: Инициализировать prefs в main.dart**

Заменить `app/lib/main.dart`:

```dart
/// Назначение: точка входа — инициализация Supabase, prefs и запуск ProviderScope.
///
/// Слой: bootstrap
/// Зависимости: supabase_flutter, flutter_riverpod, shared_preferences, core/config.
/// Ключевые типы: main().
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/storage/preferences_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnv();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ChekiPricesApp(),
    ),
  );
}
```

- [ ] **Step 8: Подключить themeMode в app.dart**

В `app/lib/app.dart`: добавить импорт `import 'core/theme/theme_mode_controller.dart';`. В `build` перед `return` добавить `final themeMode = ref.watch(themeModeControllerProvider);` и заменить `themeMode: ThemeMode.system,` на `themeMode: themeMode,`.

- [ ] **Step 9: Проверка и коммит**

Run: `cd app && dart analyze lib/core lib/main.dart lib/app.dart && flutter test test/core`
Expected: No issues; PASS.

```bash
git add app/lib/core/storage app/lib/core/theme/theme_mode_controller.dart app/lib/core/theme/theme_mode_controller.g.dart app/lib/main.dart app/lib/app.dart app/test/core
git commit -m "feat(theme): переключение темы с хранением в SharedPreferences"
```

---

## Task 8: Presentation — ProfileController (TDD) + currentUserEmailProvider

**Files:**
- Modify: `app/lib/core/auth/auth_providers.dart`
- Create: `app/lib/features/profile/presentation/controllers/profile_controller.dart`
- Test: `app/test/features/profile/presentation/controllers/profile_controller_test.dart`

- [ ] **Step 1: Добавить currentUserEmailProvider**

В `app/lib/core/auth/auth_providers.dart` после `currentSessionProvider` добавить:

```dart
/// Email текущего пользователя (или null).
final currentUserEmailProvider = Provider<String?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser?.email;
});
```

- [ ] **Step 2: Тест контроллера профиля**

Create `app/test/features/profile/presentation/controllers/profile_controller_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:ticket_app/features/profile/domain/entities/profile.dart';
import 'package:ticket_app/features/profile/presentation/controllers/profile_controller.dart';

import '../../profile_test_fakes.dart';

ProviderContainer makeContainer(FakeProfileRepository repo) => ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );

void main() {
  test('build грузит профиль', () async {
    final c = makeContainer(FakeProfileRepository(makeProfile()));
    final p = await c.read(profileControllerProvider.future);
    expect(p.displayName, 'Аня');
  });

  test('updateName обновляет состояние', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).updateName('Боря');
    final p = c.read(profileControllerProvider).requireValue;
    expect(p.displayName, 'Боря');
  });

  test('setCountry обновляет страну', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).setCountry('BY');
    expect(c.read(profileControllerProvider).requireValue.countryCode, 'BY');
  });

  test('removeAvatar сбрасывает аватар', () async {
    final repo = FakeProfileRepository(makeProfile(avatarUrl: 'https://x/a.jpg'));
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c.read(profileControllerProvider.notifier).removeAvatar();
    expect(c.read(profileControllerProvider).requireValue.avatarUrl, isNull);
  });

  test('updateAvatar задаёт avatar_url', () async {
    final repo = FakeProfileRepository(makeProfile());
    final c = makeContainer(repo);
    await c.read(profileControllerProvider.future);
    await c
        .read(profileControllerProvider.notifier)
        .updateAvatar(Uint8List(0));
    expect(c.read(profileControllerProvider).requireValue.avatarUrl, isNotNull);
  });
}
```

- [ ] **Step 3: Запустить — упадёт**

Run: `cd app && flutter test test/features/profile/presentation/controllers/profile_controller_test.dart`
Expected: FAIL (нет `profile_controller.dart`).

- [ ] **Step 4: Реализовать контроллер**

Create `app/lib/features/profile/presentation/controllers/profile_controller.dart`:

```dart
/// Назначение: контроллер состояния профиля (загрузка + мутации).
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: dart:typed_data, riverpod_annotation,
///   data/repositories/profile_repository_impl.dart, domain/entities/profile.dart.
/// Ключевые типы: ProfileController, profileControllerProvider.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile.dart';

part 'profile_controller.g.dart';

/// Асинхронное состояние профиля текущего пользователя.
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Future<Profile> build() {
    return ref.watch(profileRepositoryProvider).getCurrent();
  }

  Future<void> _mutate(Future<Profile> Function() action) async {
    state = const AsyncLoading<Profile>().copyWithPrevious(state);
    state = await AsyncValue.guard(action);
  }

  /// Меняет отображаемое имя.
  Future<void> updateName(String displayName) =>
      _mutate(() => ref.read(profileRepositoryProvider).updateName(displayName));

  /// Меняет страну.
  Future<void> setCountry(String countryCode) =>
      _mutate(() => ref.read(profileRepositoryProvider).setCountry(countryCode));

  /// Загружает новый аватар (готовые байты).
  Future<void> updateAvatar(Uint8List bytes) =>
      _mutate(() => ref.read(profileRepositoryProvider).updateAvatar(bytes));

  /// Удаляет аватар.
  Future<void> removeAvatar() =>
      _mutate(() => ref.read(profileRepositoryProvider).removeAvatar());
}
```

- [ ] **Step 5: Codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: генерируется `profile_controller.g.dart`.

- [ ] **Step 6: Запустить тест — пройдёт**

Run: `cd app && flutter test test/features/profile/presentation/controllers/profile_controller_test.dart`
Expected: PASS.

- [ ] **Step 7: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile/presentation lib/core/auth && flutter test test/features/profile`
Expected: No issues; PASS.

```bash
git add app/lib/features/profile/presentation/controllers app/lib/core/auth/auth_providers.dart app/test/features/profile/presentation
git commit -m "feat(profile): ProfileController + currentUserEmailProvider"
```

---

## Task 9: Presentation — виджеты (header, country sheet, theme sheet)

**Files:**
- Create: `app/lib/features/profile/presentation/widgets/profile_header.dart`
- Create: `app/lib/features/profile/presentation/widgets/country_picker_sheet.dart`
- Create: `app/lib/features/profile/presentation/widgets/theme_mode_sheet.dart`

- [ ] **Step 1: Шапка профиля**

Create `app/lib/features/profile/presentation/widgets/profile_header.dart`:

```dart
/// Назначение: шапка настроек — аватар, имя, email; тап ведёт к редактированию.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart,
///   shared/components/components.dart, domain/entities/profile.dart.
/// Ключевые типы: ProfileHeader.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/profile.dart';

/// Карточка с аватаром, именем и email пользователя.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.profile,
    required this.email,
    this.onTap,
    super.key,
  });

  final Profile profile;
  final String? email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!
        : 'Без имени';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: tokens.spaceXl,
            backgroundColor: scheme.primaryContainer,
            foregroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: Text(
              _initials(name),
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleMedium),
                if (email != null)
                  Text(
                    email!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '?';
    return first.toUpperCase();
  }
}
```

ПРИМЕЧАНИЕ для исполнителя: перед использованием свериться с реальной сигнатурой `AppCard` (`lib/shared/components/app_card.dart`) — поддерживает ли `onTap`/`child`. Если нет — обернуть в `InkWell`/использовать имеющиеся параметры; не вводить запрещённые примитивы. Аналогично проверить наличие токенов `spaceXl`/`spaceMd` в `app_tokens.dart`, при отсутствии — взять ближайшие существующие.

- [ ] **Step 2: Bottom-sheet выбора страны**

Create `app/lib/features/profile/presentation/widgets/country_picker_sheet.dart`:

```dart
/// Назначение: bottom-sheet выбора страны; возвращает выбранный код или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/constants/supported_countries.dart,
///   core/theme/app_tokens.dart.
/// Ключевые типы: showCountryPicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/supported_countries.dart';
import '../../../../core/theme/app_tokens.dart';

/// Показывает список стран. Возвращает код выбранной страны или null (отмена).
Future<String?> showCountryPicker(
  BuildContext context, {
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in kSupportedCountries.entries)
                RadioListTile<String>(
                  value: entry.key,
                  groupValue: current,
                  title: Text(entry.value),
                  onChanged: (v) => Navigator.of(context).pop(v),
                ),
            ],
          ),
        ),
      );
    },
  );
}
```

- [ ] **Step 3: Bottom-sheet выбора темы**

Create `app/lib/features/profile/presentation/widgets/theme_mode_sheet.dart`:

```dart
/// Назначение: bottom-sheet выбора темы оформления; возвращает ThemeMode или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: showThemeModePicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

const Map<ThemeMode, String> _kThemeLabels = {
  ThemeMode.system: 'Системная',
  ThemeMode.light: 'Светлая',
  ThemeMode.dark: 'Тёмная',
};

/// Показывает выбор темы. Возвращает выбранный [ThemeMode] или null (отмена).
Future<ThemeMode?> showThemeModePicker(
  BuildContext context, {
  required ThemeMode current,
}) {
  return showModalBottomSheet<ThemeMode>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final entry in _kThemeLabels.entries)
                RadioListTile<ThemeMode>(
                  value: entry.key,
                  groupValue: current,
                  title: Text(entry.value),
                  onChanged: (v) => Navigator.of(context).pop(v),
                ),
            ],
          ),
        ),
      );
    },
  );
}
```

ПРИМЕЧАНИЕ: `RadioListTile`/`showModalBottomSheet` — разрешённые стоковые M3 (см. карту в `design-system.md`). Свериться с именами токенов отступов в `app_tokens.dart`.

- [ ] **Step 4: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile/presentation/widgets`
Expected: No issues.

```bash
git add app/lib/features/profile/presentation/widgets
git commit -m "feat(profile): виджеты шапки профиля и bottom-sheet'ы страны/темы"
```

---

## Task 10: Presentation — EditProfileScreen (имя + аватар) + роут

**Files:**
- Create: `app/lib/features/profile/presentation/screens/edit_profile_screen.dart`
- Modify: `app/lib/core/router/app_routes.dart`
- Modify: `app/lib/core/router/app_router.dart`

- [ ] **Step 1: Добавить роут в app_routes.dart**

В `app/lib/core/router/app_routes.dart` после `profile` добавить:

```dart
  /// Редактирование профиля (имя, аватар).
  static const String editProfile = '/profile/edit';
```

- [ ] **Step 2: Экран редактирования**

Create `app/lib/features/profile/presentation/screens/edit_profile_screen.dart`:

```dart
/// Назначение: экран редактирования профиля — имя и аватар.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, flutter_riverpod, image_picker,
///   core/theme/app_tokens.dart, shared/components, data (avatar_image_processor),
///   presentation/controllers/profile_controller.dart.
/// Ключевые типы: EditProfileScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../data/avatar_image_processor.dart';
import '../controllers/profile_controller.dart';

/// Редактирование имени и аватара текущего пользователя.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = ref.read(profileControllerProvider).valueOrNull;
    _name = TextEditingController(text: current?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final raw = await file.readAsBytes();
      final processed = processAvatar(raw);
      await ref.read(profileControllerProvider.notifier).updateAvatar(processed);
    } catch (_) {
      _showError('Не удалось обновить аватар');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileControllerProvider.notifier).removeAvatar();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(profileControllerProvider.notifier).updateName(_name.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      _showError('Не удалось сохранить');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(profileControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'Редактировать профиль',
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: CircleAvatar(
                radius: tokens.spaceXl * 2,
                backgroundColor: scheme.primaryContainer,
                foregroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? Icon(Icons.person_outline,
                        color: scheme.onPrimaryContainer)
                    : null,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  label: 'Сменить фото',
                  variant: AppButtonVariant.secondary,
                  onPressed: _busy ? null : _pickAvatar,
                ),
                SizedBox(width: tokens.spaceSm),
                if (profile?.avatarUrl != null)
                  AppButton(
                    label: 'Удалить',
                    variant: AppButtonVariant.text,
                    onPressed: _busy ? null : _removeAvatar,
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceLg),
            AppTextField(
              label: 'Имя',
              controller: _name,
              prefixIcon: Icons.person_outline,
            ),
            const Spacer(),
            AppButton(
              label: 'Сохранить',
              expanded: true,
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
```

ПРИМЕЧАНИЕ: свериться с токенами (`spaceLg`, `spaceMd`, `spaceSm`, `spaceXl`) в `app_tokens.dart`; если каких-то имён нет — заменить ближайшими существующими. `image_picker` source — галерея; камеру можно добавить позже.

- [ ] **Step 3: Зарегистрировать роут в app_router.dart**

В `app/lib/core/router/app_router.dart`: добавить импорт экрана; добавить top-level `GoRoute` (вне `StatefulShellRoute`, рядом с другими top-level роутами вроде `resetPassword`):

```dart
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
```

- [ ] **Step 4: Проверка и коммит**

Run: `cd app && dart analyze lib/features/profile lib/core/router`
Expected: No issues.

```bash
git add app/lib/features/profile/presentation/screens/edit_profile_screen.dart app/lib/core/router
git commit -m "feat(profile): экран редактирования профиля (имя/аватар) + роут /profile/edit"
```

---

## Task 11: Presentation — SettingsScreen (замена ProfileScreen)

**Files:**
- Create: `app/lib/features/profile/presentation/screens/settings_screen.dart`
- Delete: `app/lib/features/profile/presentation/screens/profile_screen.dart`
- Modify: `app/lib/core/router/app_router.dart`

- [ ] **Step 1: Экран настроек**

Create `app/lib/features/profile/presentation/screens/settings_screen.dart`:

```dart
/// Назначение: экран «Настройки» — профиль, страна, тема, пароль, семья, выход.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, flutter_riverpod, go_router,
///   core/theme/*, core/auth, core/router, shared/components,
///   auth/presentation/controllers/auth_controller.dart, profile presentation.
/// Ключевые типы: SettingsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/constants/supported_countries.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../shared/components/components.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/theme_mode_sheet.dart';

/// Экран настроек приложения и профиля.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final profileAsync = ref.watch(profileControllerProvider);
    final email = ref.watch(currentUserEmailProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return AppScaffold(
      title: 'Настройки',
      body: profileAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => AppErrorView(
          message: 'Не удалось загрузить профиль',
          onRetry: () => ref.invalidate(profileControllerProvider),
        ),
        data: (profile) => ListView(
          padding: EdgeInsets.all(tokens.spaceLg),
          children: [
            ProfileHeader(
              profile: profile,
              email: email,
              onTap: () => context.push(AppRoutes.editProfile),
            ),
            SizedBox(height: tokens.spaceLg),
            AppListTile(
              title: 'Страна',
              subtitle: countryName(profile.countryCode),
              leading: const Icon(Icons.public),
              onTap: () => _changeCountry(context, ref, profile.countryCode),
            ),
            AppListTile(
              title: 'Сменить пароль',
              leading: const Icon(Icons.lock_outline),
              onTap: () => context.push(AppRoutes.resetPassword),
            ),
            SizedBox(height: tokens.spaceMd),
            AppListTile(
              title: 'Тема оформления',
              subtitle: _themeLabel(themeMode),
              leading: const Icon(Icons.brightness_6_outlined),
              onTap: () => _changeTheme(context, ref, themeMode),
            ),
            SizedBox(height: tokens.spaceMd),
            const AppListTile(
              title: 'Семья',
              subtitle: 'Скоро',
              leading: Icon(Icons.group_outlined),
              // onTap намеренно не задан — раздел в разработке.
            ),
            SizedBox(height: tokens.spaceXl),
            AppButton(
              label: 'Выйти',
              variant: AppButtonVariant.destructive,
              expanded: true,
              loading: isSigningOut,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCountry(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showCountryPicker(context, current: current);
    if (picked == null || picked == current || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сменить страну?'),
        content: const Text(
          'Изменятся фискальный провайдер и валюта будущих чеков. '
          'Ранее сохранённые чеки не изменятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сменить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(profileControllerProvider.notifier).setCountry(picked);
    }
  }

  Future<void> _changeTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showThemeModePicker(context, current: current);
    if (picked == null) return;
    await ref.read(themeModeControllerProvider.notifier).setMode(picked);
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
        ThemeMode.system => 'Системная',
      };
}
```

ПРИМЕЧАНИЕ: свериться с сигнатурой `AppListTile` (есть `subtitle`/`leading`/`onTap` — подтверждено) и токенами отступов. `AlertDialog`/`TextButton` внутри диалога — разрешены (стоковый M3 в диалоге). Проверить, что навигация на `resetPassword` уместна для залогиненного пользователя; при необходимости заменить на отдельный мини-экран ввода нового пароля, вызывающий `AuthController.resetPassword`.

- [ ] **Step 2: Удалить profile_screen.dart**

Run: `rm app/lib/features/profile/presentation/screens/profile_screen.dart`

- [ ] **Step 3: Обновить app_router.dart**

В `app/lib/core/router/app_router.dart`: заменить импорт `profile_screen.dart` на `settings_screen.dart`; в ветке профиля `builder` заменить `const ProfileScreen()` на `const SettingsScreen()`.

- [ ] **Step 4: Анализ и тесты**

Run: `cd app && dart analyze && flutter test`
Expected: No issues; все тесты PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/profile/presentation/screens app/lib/core/router/app_router.dart
git rm app/lib/features/profile/presentation/screens/profile_screen.dart 2>/dev/null || true
git commit -m "feat(profile): экран «Настройки» вместо заглушки профиля"
```

---

## Task 12: Запуск приложения и проверка на симуляторе

**Files:** нет (верификация).

- [ ] **Step 1: Запустить на iOS-симуляторе**

Запустить приложение (`app/run-dev.sh`, симулятор сначала boot + bootstatus — см. заметки проекта). Войти под тестовым пользователем.

- [ ] **Step 2: Прогнать сценарии**

Проверить: заголовок «Настройки»; шапка показывает имя/email/аватар-плейсхолдер; переход в «Редактировать профиль» → смена имени сохраняется; выбор/смена аватара (галерея) → аватар отображается; удаление аватара; смена страны → диалог-предупреждение → значение обновляется; переключение темы (системная/светлая/тёмная) применяется сразу и сохраняется после перезапуска; плитка «Семья» — disabled «Скоро»; «Сменить пароль» открывает соответствующий экран; «Выйти» работает. Проверить light/dark.

- [ ] **Step 3: Дизайн-ревью субагентом**

Запустить `flutter-design-reviewer` на изменения в `lib/features/profile/presentation/` и новых виджетах: токены вместо хардкода, Material 3, const-корректность, доступность. Исправить замечания.

- [ ] **Step 4: Финальные гейты**

Run: `cd app && dart format . && dart analyze && flutter test`
Expected: форматирование без изменений в новых файлах, No issues, все тесты PASS.

---

## Task 13: Документация фичи

**Files:**
- Modify: `docs/features/profile.md`

- [ ] **Step 1: Обновить profile.md**

Отразить реализованное: экран «Настройки», редактирование имени/аватара, смена страны с подтверждением, тема (локально), смена пароля (переиспользование auth), плитка «Семья» (заглушка). Закрыть «Открытый вопрос» по странам: список BY/RU/KZ (`core/constants/supported_countries.dart`). Указать `avatar_url` и бакет `avatars`. Перечислить Riverpod-провайдеры (`profileControllerProvider`, `profileRepositoryProvider`, `themeModeControllerProvider`).

- [ ] **Step 2: Commit**

```bash
git add docs/features/profile.md
git commit -m "docs(profile): обновление фичи profile (настройки, аватар, тема)"
```

---

## Self-review (выполнено при написании плана)

- **Покрытие спеки:** переименование (T11), шапка/имя/email (T9,T11), редактирование имени+аватара (T5,T10), показ/смена страны с подтверждением (T2,T9,T11), тема локально (T7), смена пароля (T11), семья disabled (T11), выход (T11), миграция+RLS+privacy-review (T1), документация (T1,T13), тесты (T3–T8). Все пункты спеки покрыты.
- **Типы согласованы:** `ProfileRepository` (getCurrent/updateName/setCountry/updateAvatar/removeAvatar) одинаков в контракте (T3), datasource (T6), фейках (T6), контроллере (T8). `Profile.copyWith(clearAvatar:)` определён в T3 и используется в фейках T6. `processAvatar`/`kAvatarMaxSide` (T5) используется в T10. `themeModeControllerProvider`/`setMode` (T7) — в T11. `sharedPreferencesProvider` (T7) переопределяется в main (T7).
- **Placeholders:** в UI-задачах оставлены явные ПРИМЕЧАНИЯ свериться с сигнатурами каталожных компонентов и именами токенов — это намеренная инструкция исполнителю (имена могут отличаться), а не пропуск; весь код приведён целиком.
- **Риски:** имена токенов отступов (`spaceSm/Md/Lg/Xl`) и параметры `AppCard` требуют сверки на исполнении (отмечено в задачах).
