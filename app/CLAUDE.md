# Flutter-клиент ChekiPrices (`app/`)

Конвенции этого подпроекта. Полные правила — `../docs/conventions/flutter.md`.
Перед реализацией фичи читай `../docs/features/<feature>.md`.

## Архитектура

- Feature-first: `lib/features/<feature>/{data,domain,presentation}/`.
- Зависимости внутрь: `presentation → domain ← data`. `domain` ни от чего не зависит.
- Инфраструктура — `lib/core/`; переиспользуемое — `lib/shared/`.

## DI / состояние / навигация

- DI через Riverpod-провайдеры: `SupabaseClient → datasource → repository →
  usecase → controller`.
- Codegen: `dart run build_runner build --delete-conflicting-outputs`.
- Навигация: `GoRouter` с `redirect` по `authStateChanges` (`core/router/`).
- Realtime: подписка на строку чека через `core/realtime/`.

## Команды

- `flutter pub get`
- `dart run build_runner build --delete-conflicting-outputs`
- `dart analyze`
- `flutter test`

## Документация файла

Каждый `.dart`-файл — с dartdoc-шапкой по шаблону из
`../docs/conventions/documentation.md`.
