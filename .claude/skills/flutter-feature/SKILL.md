---
name: flutter-feature
description: Каркасит новую фичу Flutter в ChekiPrices по конвенциям проекта — трёхслойная структура data/domain/presentation с dartdoc-шапками, доменными контрактами и Riverpod-провайдерами. Используй, когда нужно добавить/начать фичу в lib/features/, либо когда пользователь вызывает /flutter-feature <name>.
argument-hint: "<feature-name> (snake_case, напр. price_compare)"
---

# Каркас фичи Flutter (ChekiPrices)

Цель — создать структуру новой фичи строго по конвенциям проекта, БЕЗ выдумывания
бизнес-логики сверх описанного в документации.

## Шаг 0. Прочитай контекст (обязательно)
1. `docs/features/<feature>.md` — назначение, сценарии, сущности БД, репозитории,
   use-cases, Riverpod-провайдеры, RLS, взаимодействие с воркером. Это ТЗ фичи.
   Если файла нет — сначала создай его по шаблону из `docs/conventions/documentation.md`
   и согласуй с пользователем.
2. `app/CLAUDE.md` и `docs/conventions/flutter.md` — слои, зависимости, codegen, именование.
3. Образец оформления — `app/lib/features/profile/domain/` (уже в репозитории).

## Шаг 1. Имя и расположение
- Каталог фичи — `snake_case`: `app/lib/features/<feature>/`.
- Если фича уже есть как пустой скелет (только `.gitkeep`) — наполняй его.

## Шаг 2. Слои (создавай только то, что описано в docs/features/<feature>.md)
- `domain/entities/` — чистые сущности (без зависимостей от Flutter/Supabase).
- `domain/repositories/` — абстрактные контракты (`abstract interface class`).
- `domain/usecases/` — сценарии (по одному классу на сценарий).
- `data/models/` — DTO (freezed + json_serializable), маппинг в доменные сущности.
- `data/datasources/` — обращения к Supabase (PostgREST/Realtime/Storage).
- `data/repositories/` — реализации доменных контрактов.
- `presentation/controllers/` — Riverpod-нотифаеры (`@riverpod`, codegen).
- `presentation/screens/` и `presentation/widgets/` — UI на токенах темы.

## Шаг 3. Правила, которые соблюдай
- **Шапки файлов:** каждый `.dart` — с dartdoc-заголовком (Назначение, Слой, Фича,
  Зависимости, Ключевые типы) по `docs/conventions/documentation.md`.
- **Зависимости внутрь:** `presentation → domain ← data`; `domain` ни от чего не зависит.
- **DI:** цепочка провайдеров `SupabaseClient → datasource → repository → usecase →
  controller` (см. `lib/core/di/`).
- **Riverpod codegen:** `@riverpod`; для мутируемого async-стейта — `AsyncNotifier`.
- **Дизайн-система:** в UI — токены темы (`Theme.of(context)`, `ThemeExtension`,
  `lib/core/theme/`), НЕ `Colors.*` / `Color(0x..)` / сырые `TextStyle(`.
- **YAGNI:** не добавляй методы/экраны, которых нет в ТЗ фичи.

## Шаг 4. После каркаса
- Запусти `cd app && dart run build_runner build --delete-conflicting-outputs`,
  затем `dart analyze` — добейся чистого вывода.
- Обнови `docs/features/<feature>.md`, если структура отошла от описания.
- Покажи пользователю дерево созданных файлов и предложи следующий шаг (реализация
  конкретного use-case через TDD).
