# Фича: auth

## Назначение
Аутентификация: email+пароль и OAuth (Google/Apple), управление сессией.
Телефон/OTP — позже (вне текущего этапа).

## Пользовательские сценарии
- Регистрация по email+паролю с выбором страны (передаётся в профиль).
- Вход по email+паролю и через OAuth.
- Автологин по сохранённой сессии; выход.

## Экраны / UI
Sign in, Sign up, восстановление пароля.

## Задействованные сущности БД
`profiles` (создаётся при первой регистрации).

## Репозитории и use-cases
`AuthRepository` (signIn/signUp/signOut/currentSession); use-cases входа/выхода/регистрации.

## Riverpod-провайдеры
`authStateChanges` (стрим сессии Supabase), `authControllerProvider`.

## Затрагиваемые RLS-политики
Зона A: создание `profiles` по `auth.uid()`.

## Взаимодействие с воркером
Нет.

## Реализовано (v1)
- Email+пароль: вход, регистрация (со страной → user_metadata), восстановление пароля.
- Обязательное подтверждение email; ссылки приходят deep link `chekiprices://login-callback`.
- Профиль создаётся триггером `handle_new_user` (см. `../architecture/data-model.md`).
- Навигация: redirect по стриму `onAuthStateChange` (`core/auth` + `core/router`).
- Письма — встроенный SMTP Supabase (v1).

## Отложено
- OAuth (Google/Apple), телефон/OTP.
- Кастомный SMTP + домен + правка email-шаблонов (шаг деплоя перед релизом).
- Список стран в `CountryField` — синхронизировать с `fiscal_providers`.
- Минимальные требования к паролю на клиенте.
- FK `profiles.family_id → families(id)` — добавить при создании зоны D.

## Шаги деплоя (вне кода)
- Применить миграцию `supabase/migrations/0001_auth_profiles.sql`.
- В настройках Supabase Auth: включить «Confirm email», добавить
  `chekiprices://login-callback` в список разрешённых Redirect URLs.
