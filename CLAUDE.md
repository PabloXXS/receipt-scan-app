# ChekiPrices — обзор для Claude Code

Мобильное приложение умного учёта покупок: сканирование QR/фото кассового чека →
разбор на товары → статистика трат, сравнение цен между магазинами, карты
лояльности, семейный учёт, обезличенная карта цен по региону.

## Стек

| Слой | Технологии |
|---|---|
| Клиент (`app/`) | Flutter, Riverpod (codegen), GoRouter, freezed/json_serializable |
| Платформа | Supabase: Postgres + RLS, Auth, Storage, Realtime, pgmq |
| Воркер (`worker/`) | PHP 8.2+ (Composer, PSR-4), демон над очередью pgmq |

## Карта репозитория

- `app/` — Flutter-клиент. Конвенции: `app/CLAUDE.md`.
- `worker/` — PHP-воркер обработки чеков. Конвенции: `worker/CLAUDE.md`.
- `docs/` — документация (источник истины). Карта: `docs/README.md`.

## Как запускать

- Клиент: `cd app && flutter pub get && flutter run`
- Воркер: `cd worker && composer install && php bin/worker.php`

## Дисциплина «живой» документации (ОБЯЗАТЕЛЬНО)

1. **Перед реализацией фичи** прочитай `docs/features/<feature>.md` и нужный
   `docs/conventions/*.md`.
2. **После изменения кода** обнови файл фичи; при изменении схемы БД —
   `docs/architecture/data-model.md`.
3. **Архитектурное решение** → новый `docs/adr/NNNN-*.md`.
4. **Каждый созданный файл кода** — с шапкой-документацией по шаблону из
   `docs/conventions/documentation.md`.

## ⛔ Инвариант приватности (НЕ нарушать)

Обезличенная карта цен (зона C: `prices`, `price_aggregates`) **никогда** не содержит
`user_id` или `family_id`. Единственная точка отрыва наблюдений от пользователя —
`worker/src/Privacy/PriceAnonymizer.php` и `worker/src/Pipeline/Steps/PublishPricesStep.php`.
Любое изменение схемы цен или кода публикации цен проверяй субагентом
`privacy-rls-reviewer`. Подробности — `docs/architecture/privacy.md`.

## Автоматизации Claude Code (`.claude/`)

- **MCP** (`.mcp.json`): `dart` (анализ/тесты/формат/pub/hot-reload), `supabase`
  (схема, RLS, миграции), `context7` (живая документация — `use riverpod`/`use supabase`).
- **Скиллы:** `/flutter-feature <name>` — каркас фичи по конвенциям;
  `/supabase-migration <name>` — миграция с RLS по зонам A–D и проверкой зоны C.
- **Субагенты:** `privacy-rls-reviewer` (приватность/RLS), `flutter-design-reviewer`
  (UI/дизайн-система).
- **Хуки:** авто-`dart format` после правок; запрет правок `.env`; ненавязчивые
  напоминания о дизайн-системе и инварианте приватности.

## Границы текущего этапа

Реальная бизнес-логика фич, интеграции с фискальными API и OCR-движок ещё НЕ
реализованы — в репозитории только структура, документация и заглушки. Каждая
последующая фича идёт циклом spec → plan → implementation.
