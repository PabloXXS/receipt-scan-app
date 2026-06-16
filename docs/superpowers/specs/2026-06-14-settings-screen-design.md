# Дизайн: экран «Настройки» (фича profile)

Дата: 2026-06-14
Статус: утверждён к реализации
Ветка: feat/scan

## Цель

Превратить экран-заглушку «Профиль» в полноценный экран «Настройки»:
- показать профиль (аватар, имя, email);
- редактировать имя и аватар;
- показать и сменить страну (влияет на фискального провайдера и валюту);
- переключать тему оформления (светлая/тёмная/системная);
- сменить пароль;
- точка входа «Семья» (заглушка «Скоро»);
- выход из аккаунта.

## Объём итерации

В объёме: переименование, шапка профиля, редактирование имени+аватара
(`/profile/edit`), показ/смена страны с подтверждением, переключение темы
(хранение локально), смена пароля (переиспользование `resetPassword`), плитка
«Семья» = disabled «Скоро», кнопка «Выйти».

Вне объёма: удаление аккаунта, смена email, экран family, push/email-уведомления,
синхронизация темы между устройствами, i18n. Перечислены для будущих итераций.

## Ключевые решения

| Решение | Выбор |
|---|---|
| Хранение темы | Локально (`shared_preferences`), без `profiles.settings` |
| Аватар | Полноценно: колонка `avatar_url` + Storage-бакет `avatars` + выбор/кроп/загрузка |
| Смена страны | С подтверждением через `AlertDialog`; затрагивает только будущие чеки |
| Семья | Disabled-плитка «Скоро» (экрана `/family` ещё нет) |
| Смена пароля | Переиспользуем `AuthController.resetPassword` (Supabase `updateUser(password:)`) |
| Структура экрана | Один `SettingsScreen` (список) + отдельный full-screen роут `/profile/edit` |

## БД и Supabase

- Миграция: `alter table profiles add column avatar_url text null;`
- Storage-бакет `avatars` (public-read). Путь объекта: `{auth.uid}/avatar.jpg`.
- RLS на `storage.objects` для бакета `avatars`:
  - `select` — публично (бакет public);
  - `insert`/`update`/`delete` — только в свою папку: первый сегмент пути
    (`storage.foldername(name)[1]`) равен `auth.uid()::text`.
- Зона A (данные пользователя). Зоны цен (C) не затрагиваются.
- После написания миграции и RLS — проверка субагентом `privacy-rls-reviewer`.
- Обновить `docs/architecture/data-model.md` (новая колонка) и
  `docs/features/profile.md` (закрыть открытый вопрос по странам: BY/RU/KZ).

## Domain

- `Profile`: добавить поле `avatarUrl` (`String?`).
- `ProfileRepository` (существует: `getCurrent()`, `update(Profile)`) — дополнить
  загрузкой/удалением аватара. Вариант: методы `uploadAvatar(bytes)` →
  возвращает URL, `removeAvatar()`. Use-case `UpdateProfile` при необходимости
  (контроллер может вызывать репозиторий напрямую — следуем образцу receipts).

## Data

- `profile_dto.dart` — маппинг строки PostgREST `profiles` ↔ `Profile`
  (по образцу `receipts` DTO), включая `avatar_url`.
- `profile_remote_datasource.dart` — Supabase: `select`/`update` строки профиля,
  upload/remove объекта в Storage-бакете `avatars`.
- `profile_repository_impl.dart` — реализация контракта, маппинг ошибок в
  доменные failure (по образцу receipts, если там есть `ReceiptsFailure` —
  завести аналогичный `ProfileFailure` либо переиспользовать общий механизм).
- DI: `SupabaseClient → ProfileRemoteDatasource → ProfileRepository`.

## Presentation

- `ProfileController` — `@riverpod class ProfileController` (`AsyncNotifier<Profile>`):
  - `build()` — загрузка профиля текущего пользователя;
  - `updateName(String)`, `setCountry(String)`, `updateAvatar(bytes)`,
    `removeAvatar()` — мутации с обновлением состояния.
- `SettingsScreen` (переименовать `profile_screen.dart`/класс `ProfileScreen`
  → `settings_screen.dart`/`SettingsScreen`), `title: 'Настройки'`. Тело —
  список секций из `AppListTile`/`AppCard`:
  1. Шапка профиля (тап → `/profile/edit`).
  2. «Аккаунт»: страна (→ bottom-sheet), смена пароля.
  3. «Оформление»: тема (→ селектор).
  4. «Семья»: disabled «Скоро».
  5. «Выйти» (как сейчас, `AuthController.signOut`).
- Виджеты:
  - `profile_header.dart` — аватар (`CircleAvatar`/плейсхолдер) + имя + email.
  - `country_picker_sheet.dart` — `showModalBottomSheet` со списком стран.
  - `theme_mode_sheet.dart` — выбор `ThemeMode` (Radio/список).
- `EditProfileScreen` (`/profile/edit`): `AppTextField` (имя) + блок аватара
  (выбрать/заменить/удалить) с лоадером и обработкой ошибок; сохранение через
  `ProfileController`.

### Каталог стран

Вынести `kSupportedCountries` из
`features/auth/presentation/widgets/country_field.dart` в общее место
(`core/` или `shared/`), чтобы и auth, и profile зависели от единого источника.
`CountryField` (auth) переключить на новый импорт.

## Тема (core)

- `core/storage/preferences_providers.dart`: `sharedPreferencesProvider`
  (Provider, переопределяемый в `main.dart`). В `main.dart` — `await
  SharedPreferences.getInstance()` и `ProviderScope(overrides: [...])` для
  синхронного доступа.
- `core/theme/theme_mode_controller.dart`: `@riverpod class ThemeModeController`
  — `ThemeMode build()` читает ключ `theme_mode` из prefs (по умолчанию
  `system`), `setMode(ThemeMode)` пишет и обновляет состояние.
- `app.dart`: `themeMode: ref.watch(themeModeControllerProvider)`.

## Навигация

- `app_routes.dart`: `static const String editProfile = '/profile/edit';`
- `app_router.dart`: отдельный top-level `GoRoute(editProfile)` (вне
  `StatefulShellRoute` → полноэкранно, без нижнего меню).

## Смена страны

1. Bottom-sheet выбора страны (текущая отмечена).
2. При выборе новой → `AlertDialog`: предупреждение, что сменятся фискальный
   провайдер и валюта будущих чеков, ранее сохранённые чеки не изменятся.
3. При подтверждении — `ProfileController.setCountry` пишет `country_code`.
   Существующие чеки не трогаем.

## Аватар

1. `image_picker` (галерея/камера).
2. Центр-квадрат-кроп + даунскейл через пакет `image` (без новой зависимости):
   сторона ≤ 512px, JPEG q≈85.
3. Upload в `avatars/{uid}/avatar.jpg` (upsert), сохранить публичный URL в
   `profiles.avatar_url`.
4. Удаление: стереть объект Storage + `avatar_url = null`.
5. Пустой аватар → плейсхолдер (инициалы/иконка).

## Документация и тесты

- Dartdoc-шапки во всех новых `.dart`-файлах (шаблон
  `docs/conventions/documentation.md`).
- Обновить `docs/features/profile.md`, `docs/architecture/data-model.md`.
- Тесты: DTO-маппинг, репозиторий (fakes по образцу
  `test/features/receipts/...`), контроллер.
- Гейты: `dart analyze` без ошибок, `flutter test` зелёный, `dart format`.
- UI работает в light/dark.

## Затрагиваемые файлы (ориентир)

Новые: `profile_dto.dart`, `profile_remote_datasource.dart`,
`profile_repository_impl.dart`, `profile_controller.dart`, `settings_screen.dart`,
`edit_profile_screen.dart`, `profile_header.dart`, `country_picker_sheet.dart`,
`theme_mode_sheet.dart`, `core/storage/preferences_providers.dart`,
`core/theme/theme_mode_controller.dart`, общий модуль стран, миграция Supabase.

Изменяемые: `profile.dart` (сущность), `profile_repository.dart` (контракт),
`app.dart`, `main.dart`, `app_routes.dart`, `app_router.dart`, `country_field.dart`,
`docs/features/profile.md`, `docs/architecture/data-model.md`.

Удаляемые: `profile_screen.dart` (переименование в `settings_screen.dart`).
