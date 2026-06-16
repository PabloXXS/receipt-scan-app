# Фича: profile

## Назначение
Экран «Настройки»: управление профилем пользователя (аватар, отображаемое имя, email),
смена страны (влияет на фискального провайдера и валюту будущих чеков), выбор темы
оформления, смена пароля, заглушка раздела «Семья», выход из аккаунта.

## Пользовательские сценарии
- Просмотреть профиль: шапка с аватаром, именем и email.
- Редактировать профиль (экран `/profile/edit`): изменить `display_name`; загрузить
  аватар из галереи (центр-кроп/даунскейл до 512 px → JPEG → Storage `avatars`) или
  удалить аватар.
- Сменить страну: выбор через bottom-sheet → подтверждение диалогом (`AlertDialog`);
  меняет фискального провайдера и валюту **будущих** чеков; ранее сохранённые чеки
  не изменяются.
- Переключить тему оформления (светлая / тёмная / системная): хранится локально в
  `SharedPreferences`, применяется немедленно, сохраняется между сеансами.
- Сменить пароль: переход к существующему auth-экрану (`AppRoutes.resetPassword`).
- Раздел «Семья»: отображается как disabled-плитка «Скоро» (фича не реализована).
- Выйти из аккаунта.

## Экраны / UI

| Экран | Класс | Роут |
|---|---|---|
| Настройки | `SettingsScreen` | `/profile` (таб) |
| Редактирование профиля | `EditProfileScreen` | `/profile/edit` (`AppRoutes.editProfile`) |

**Виджеты:**
- `ProfileHeader` — шапка с аватаром (`CircleAvatar` + `NetworkImage`), именем, email;
  тап ведёт к `EditProfileScreen`.
- `CountryPickerSheet` (`showCountryPicker`) — bottom-sheet выбора страны из
  `kSupportedCountries`.
- `ThemeModeSheet` (`showThemeModePicker`) — bottom-sheet выбора темы.

## Задействованные сущности БД

| Таблица | Поля | Зона |
|---|---|---|
| `profiles` | `id`, `country_code`, `display_name`, `avatar_url`, `family_id` | A (per-user) |

**Storage:** бакет `avatars` (публичное чтение; запись/обновление/удаление —
только в папку `{auth.uid}/`). Путь файла: `{uid}/avatar.jpg`.
`profiles.avatar_url` хранит публичный URL с cache-bust-параметром (`?v=<ts>`).

## Репозитории и use-cases

- `ProfileRepository` (контракт): `getCurrent`, `updateName`, `setCountry`,
  `updateAvatar`, `removeAvatar`.
- `ProfileRepositoryImpl` (реализация): делегирует `SupabaseProfileRemoteDataSource`,
  оборачивает исключения в `ProfileFailure`.
- `SupabaseProfileRemoteDataSource`: PostgREST (`profiles`) + Storage (`avatars`).
- `processAvatar` (`data/avatar_image_processor.dart`): центр-кроп в квадрат,
  даунскейл до 512 px, JPEG q=85.
- `ProfileErrorMapper` (`data/profile_error_mapper.dart`): `SocketException` →
  `ProfileNetworkFailure`; `StorageException` → `ProfileAvatarFailure`;
  `PostgrestException` → `ProfileLoadFailure`.

## Riverpod-провайдеры

| Провайдер | Тип | Назначение |
|---|---|---|
| `profileControllerProvider` | `AsyncNotifier<Profile>` (codegen) | Состояние профиля + мутации |
| `profileRepositoryProvider` | `Provider<ProfileRepository>` | DI репозитория |
| `profileRemoteDataSourceProvider` | `Provider<ProfileRemoteDataSource>` | DI datasource |
| `themeModeControllerProvider` | `Notifier<ThemeMode>` (codegen) | Текущая тема, хранится в `SharedPreferences` (ключ `theme_mode`) |
| `sharedPreferencesProvider` | `Provider<SharedPreferences>` | Переопределяется в `main.dart` |
| `currentUserEmailProvider` | `Provider<String?>` | Email текущего пользователя из `SupabaseClient.auth` |

## Затрагиваемые RLS-политики

**Таблица `profiles` (зона A):** `SELECT`/`UPDATE` по `auth.uid() = id`.

**Storage `avatars`:**
- `avatars_public_read` — публичный `SELECT` для всех.
- `avatars_insert_own` / `avatars_update_own` / `avatars_delete_own` —
  запись только в свою папку (`storage.foldername(name)[1] = auth.uid()`).

Миграция: `supabase/migrations/0005_profile_avatar.sql`.

## Взаимодействие с воркером
Косвенно: `country_code` из `profiles` определяет фискального провайдера в воркере при
разборе чека. Смена страны изменяет поведение только для **новых** чеков.

## Поддерживаемые страны
BY (Беларусь), RU (Россия), KZ (Казахстан).
Каталог: `app/lib/core/constants/supported_countries.dart` (`kSupportedCountries`, `countryName`).
