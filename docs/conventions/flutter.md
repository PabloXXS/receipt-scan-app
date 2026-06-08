# Конвенции Flutter (`app/`)

## Архитектура

- Feature-first: `lib/features/<feature>/{data,domain,presentation}/`.
- Зависимости направлены внутрь: `presentation → domain ← data`.
  `domain` не зависит ни от `data`, ни от `presentation`.
- Общая инфраструктура — в `lib/core/`; переиспользуемый UI/DTO — в `lib/shared/`.

## Слои фичи

- `data/` — `datasources/` (Supabase/PostgREST), `models/` (DTO, freezed+json),
  `repositories/` (реализации доменных интерфейсов).
- `domain/` — `entities/` (чистые сущности), `repositories/` (абстракции),
  `usecases/` (сценарии).
- `presentation/` — `controllers/` (Riverpod-нотифаеры), `screens/`, `widgets/`.

## DI и состояние

- DI через Riverpod-провайдеры. Цепочка:
  `SupabaseClient → datasource → repository → usecase → controller`.
  Отдельных DI-пакетов нет.
- Codegen: `riverpod_generator`, `freezed`, `json_serializable`.
  Генерация: `dart run build_runner build --delete-conflicting-outputs`.

## Навигация

- `GoRouter` с `redirect` по `authStateChanges` (см. `core/router/`).

## Realtime

- В фиче `receipts` контроллер подписывается на строку чека через
  хелперы `core/realtime/`.

## Именование

- Файлы — `snake_case.dart`. Классы — `UpperCamelCase`. Провайдеры — `camelCase`.
- Тесты зеркалят `lib/` в `test/`, суффикс `_test.dart`.

## Документация файла

Каждый файл — с dartdoc-шапкой по шаблону из `documentation.md`.
