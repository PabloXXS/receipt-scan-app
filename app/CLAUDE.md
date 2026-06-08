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

## Riverpod (best practices)

- Провайдеры через codegen: аннотация `@riverpod` + `riverpod_generator`.
- Для мутируемого асинхронного состояния — класс-нотифаер `AsyncNotifier`
  (генерируется из `@riverpod class ...`), а не связка `FutureProvider` + ручной стейт.
- Параметризация — через именованные аргументы генерируемого провайдера, а не `family`.
- В `build` контроллера — никакой тяжёлой логики и сайд-эффектов.

## Дизайн-система (правила)

- **Единая тема** в `lib/core/theme/`. Палитра — `ColorScheme.fromSeed(...)`,
  `useMaterial3: true`.
- **Брендовые токены** (отступы, радиусы, кастомные цвета, длительности) — через
  `ThemeExtension<T>`, доступ `Theme.of(context).extension<...>()`.
- **В фичах и shared запрещено:** `Colors.*`, `Color(0xFF..)`, сырые `TextStyle(`,
  магические числа отступов. Используй `Theme.of(context).colorScheme/.textTheme`
  и токены-расширения. (Напоминание включено хуком `flutter-guards`.)
- UI должен корректно работать в light/dark без хардкода.
- Перенос макетов из Figma — через скиллы `figma-generate-design` / `figma-code-connect`
  с привязкой к токенам, а не пиксельным хардкодом.

## Инструменты

- Скилл `/flutter-feature <name>` — каркас новой фичи по этим конвенциям.
- Субагент `flutter-design-reviewer` — ревью UI и дизайн-системы.
- MCP `dart` — анализ/тесты/формат; `context7` — `use riverpod` для актуальных API.

## Документация файла

Каждый `.dart`-файл — с dartdoc-шапкой по шаблону из
`../docs/conventions/documentation.md`.
