# Документация ChekiPrices

Источник истины для разработки через Claude Code. Перед задачей читай
релевантные файлы (см. правило в корневом `CLAUDE.md`).

## Карта

- **architecture/** — как устроена система:
  - `overview.md` — компоненты и поток данных.
  - `data-model.md` — таблицы, поля, связи, RLS-зоны A–D.
  - `data-flow.md` — жизненный цикл чека от скана до статистики.
  - `privacy.md` — модель приватности и анонимизации цен.
- **features/** — по одному файлу на фичу (единый шаблон): `auth`, `scan`,
  `receipts`, `statistics`, `price-compare`, `loyalty-cards`, `family`,
  `profile`.
- **conventions/** — правила кодирования: `flutter.md`, `php-worker.md`,
  `documentation.md`.
- **adr/** — Architecture Decision Records: `0001-pgmq-queue.md`.
- **specs/** — дизайн-доки (выход brainstorming).
- **superpowers/plans/** — планы реализации.
