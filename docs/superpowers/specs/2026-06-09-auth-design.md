# Дизайн фичи: авторизация (auth) — v1

Дата: 2026-06-09
Статус: утверждён, готов к написанию плана реализации.

## Назначение

Аутентификация пользователя ChekiPrices: регистрация и вход по email+паролю,
восстановление пароля, управление сессией и навигация по auth-состоянию.
OAuth (Google/Apple) и телефон/OTP — вне текущей итерации.

## Утверждённые решения (v1)

1. **Способы входа:** только email+пароль + восстановление пароля. OAuth — отдельная итерация.
2. **Подтверждение email:** обязательное (после `signUp` сессии нет до подтверждения).
3. **Создание профиля:** DB-триггер `handle_new_user` на `auth.users`; `country_code`
   берётся из `raw_user_meta_data` (передаётся при `signUp`).
4. **Email-ссылки:** deep link в приложение — custom URL scheme `chekiprices://login-callback`;
   `supabase_flutter` (PKCE) поднимает сессию автоматически.
5. **Отправка писем:** на v1 — встроенный SMTP Supabase (с лимитами, риск спама — временно
   для разработки). Кастомный SMTP + домен + правка шаблонов — отдельная prod-задача инфры,
   код фичи при этом не меняется.
6. **Навигация:** стрим `authStateChanges` (Supabase) — источник истины для наличия сессии
   и redirect; `authControllerProvider` (`AsyncNotifier`) — только состояние действий форм
   (loading/error signIn/signUp/reset).
7. Фича приносит **первую миграцию БД проекта** (`profiles`, RLS зона A, триггер).

## Архитектура (связка состояние ↔ навигация)

Выбран подход «стрим — источник истины + `refreshListenable`»:

- `authStateChanges` (стрим Supabase) — единственный источник истины о наличии сессии.
- `GoRouter.redirect` синхронно читает текущую сессию из провайдера; `refreshListenable`
  (обёртка `GoRouterRefreshStream` над стримом) триггерит пересчёт redirect при любом
  изменении сессии (вход/выход/подтверждение по deep link).
- `authControllerProvider` (`AsyncNotifier`) отвечает только за действия и их состояние,
  не дублирует «кто залогинен».

Отклонённая альтернатива: `AsyncNotifier` как источник истины для роутинга — избыточно
для email+пароль, дублирует стрим Supabase, легче рассинхронизировать с реальной сессией.

## Структура (feature-first, зависимости внутрь)

```
features/auth/
  data/
    datasources/   auth_remote_datasource.dart   (обёртка SupabaseClient.auth / GoTrue)
    repositories/  auth_repository_impl.dart      (маппинг исключений → Failure)
  domain/
    entities/      auth_session.dart, auth_user.dart
    repositories/  auth_repository.dart
    usecases/      sign_in.dart, sign_up.dart, sign_out.dart,
                   request_password_reset.dart, reset_password.dart
  presentation/
    controllers/   auth_controller.dart            (@riverpod AsyncNotifier — действия форм)
    screens/       sign_in_screen.dart, sign_up_screen.dart,
                   forgot_password_screen.dart, reset_password_screen.dart,
                   check_email_screen.dart
    widgets/       auth_form_fields.dart            (поля e-mail/пароль на каталоге shared)
```

Глобальное (`core/`):
- `core/auth/auth_providers.dart` — `authStateChangesProvider` (стрим),
  `currentSessionProvider`, `GoRouterRefreshStream`.
- `core/router/app_router.dart` — redirect по auth-состоянию + маршруты auth.
- `core/error/failure.dart` — добавить `AuthFailure`.

## Доменные контракты

`AuthRepository`:
- `Stream<AuthSession?> authStateChanges()`
- `AuthSession? get currentSession`
- `Future<void> signIn({required String email, required String password})`
- `Future<void> signUp({required String email, required String password, required String countryCode})`
  — `countryCode` уходит в `user_metadata`.
- `Future<void> signOut()`
- `Future<void> requestPasswordReset(String email)` — письмо с deep-link redirect.
- `Future<void> resetPassword(String newPassword)` — после захода по recovery-ссылке.

Каждый use-case — тонкая обёртка над методом репозитория. Use-cases бросают `Failure`;
контроллер ловит и кладёт в `AsyncValue.error`.

## Поток данных (ключевые сценарии)

- **Регистрация:** форма → `signUp` (`countryCode` в metadata) → Supabase создаёт `auth.users`
  → триггер `handle_new_user` создаёт `profiles` → сессии нет (нужно подтверждение)
  → переход на `check_email_screen`.
- **Подтверждение:** письмо → deep link `chekiprices://login-callback` → `supabase_flutter`
  поднимает сессию → `authStateChanges` эмитит → `refreshListenable` → redirect на `/`.
- **Вход:** форма → `signIn` → сессия → redirect на home.
- **Сброс пароля:** `forgot_password` → `requestPasswordReset` → письмо → deep link recovery
  → `reset_password_screen` → `resetPassword(new)` → сессия активна → home.
- **Выход:** `signOut` → стрим эмитит `null` → redirect на `/sign-in`.

## База данных (первая миграция: `supabase/migrations/NNNN_auth_profiles.sql`, зона A)

- Таблица `profiles`: `id uuid PK (= auth.uid)`, `country_code`, `display_name`,
  `family_id nullable`, `settings jsonb`, `created_at`, `updated_at`.
- RLS зона A: `select/insert/update` по `auth.uid() = id`.
- Функция-триггер `handle_new_user()` (`SECURITY DEFINER`) на `auth.users` →
  вставка `profiles` с `country_code` из `raw_user_meta_data`.
- Триггер `updated_at`.

Миграцию обязательно проверить субагентом `privacy-rls-reviewer` (зона A, согласованность
RLS) и применять по скиллу `/supabase-migration`. После — синхронизировать
`docs/architecture/data-model.md` (зафиксировать триггер).

## Обработка ошибок

`core/error/failure.dart` расширяется sealed-кейсами `AuthFailure`:
`invalidCredentials`, `emailNotConfirmed`, `emailAlreadyRegistered`, `weakPassword`,
`network`, `unknown`. `auth_repository_impl` маппит `AuthException`/`AuthApiException`
(GoTrue) в эти кейсы. UI показывает сообщения через локализацию (`app_en.arb` + русская
локаль) и компоненты каталога (`AppErrorView` / инлайн под полем).

## UI и дизайн-система

Все экраны — только на каталоге `shared/components` (`AppScaffold`, `AppTextField`,
`AppButton`, `AppLoader`, `AppErrorView`), без сырого Material и хардкода (хук
`flutter-guards` + субагент `flutter-design-reviewer`). Light/dark обязателен.
Выбор страны при регистрации — `DropdownButtonFormField` по списку поддерживаемых стран
(источник — `country_code`/`fiscal_providers`); отдельный shared-компонент — только при
повторе паттерна (≥2).

## Отправка писем

Письма шлёт сам Supabase Auth, не приложение (код вызывает `signUp` /
`resetPasswordForEmail`). v1 — встроенный SMTP. Переход на кастомный SMTP — конфигурация
проекта, код фичи не меняется.

## Нативная конфигурация deep links

- Android: intent-filter на `chekiprices://login-callback` в `AndroidManifest.xml`.
- iOS: `CFBundleURLTypes` в `Info.plist`.
- Supabase: добавить redirect URL в Auth-настройках.
- `supabase_flutter` обрабатывает входящую сессию автоматически (PKCE).

## Тестирование

- Unit: use-cases и `auth_repository_impl` (маппинг `AuthException` → `AuthFailure`) на моках datasource.
- Контроллер: переходы `AsyncValue` (loading → data/error) на фейковом репозитории.
- Router: redirect-логика (нет сессии → `/sign-in`; есть → `/`).
- Тесты зеркалят `lib/` в `test/`; учесть заглушку `google_fonts` v8 (`test/flutter_test_config.dart`).
- Воркер не затрагивается.

## Открытые вопросы (закрыть в плане)

- Точный список поддерживаемых стран для дропдауна на старте (зависит от `fiscal_providers`).
- Минимальные требования к паролю на клиенте (длина/символы) — синхронно с настройками Supabase.

## Затрагиваемые документы

- `docs/features/auth.md` — обновить после реализации (закрыть открытые вопросы).
- `docs/architecture/data-model.md` — зафиксировать триггер `handle_new_user`.
- Возможен ADR по выбору «стрим как источник истины для навигации», если решение сочтём
  значимым архитектурно.
