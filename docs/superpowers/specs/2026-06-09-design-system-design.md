# Дизайн-система ChekiPrices (дизайн-документ)

- **Дата:** 2026-06-09
- **Статус:** утверждён (brainstorming)
- **Объём итерации:** токены темы + стартовый каталог компонентов + правила/документация/
  автоматизация соблюдения. Реальные экраны фич — НЕ сейчас (общий цикл spec→plan→implementation).

## 1. Решения (зафиксировано)

| Аспект | Выбор |
|---|---|
| Визуальный язык | Material 3 + собственный бренд (стоковые M3-виджеты + слой токенов + тонкий каталог-обёртка) |
| Бренд-вводные | Нет готовых; стартуем с seed-цвета |
| Seed-цвет | Тёпло-зелёный/emerald `#2E7D5B` (ассоциация: деньги/экономия/доверие); меняется одной константой |
| Типографика | `google_fonts`, шрифт **Inter** (хорошо читает суммы/цифры; допускается бандл для офлайна) |
| Темы | Светлая + тёмная из одного seed с самого начала |
| Строгость правил | Гибрид: каталог `shared/` обязателен для примитивов; стоковый Material — только для разметки |

## 2. Фундамент: токены и тема (`lib/core/theme/`)

Единый источник визуальных значений.

- **`app_colors.dart`** — seed-цвет (`#2E7D5B`) + семантические бренд-цвета, которых нет
  в `ColorScheme`: `success`, `warning` (бюджеты), `priceUp`, `priceDown` (сравнение цен).
  Заданы парами для light/dark.
- **`app_typography.dart`** — `TextTheme` через `google_fonts` (Inter), согласованный с M3
  типографической шкалой.
- **`app_tokens.dart`** — `ThemeExtension<AppTokens>` с токенами:
  - **spacing:** `xs=4, sm=8, md=12, lg=16, xl=24, xxl=32`;
  - **radii:** `sm=8, md=12, lg=16, pill=999`;
  - **durations:** `fast=150ms, normal=250ms`;
  - семантические цвета из `app_colors` (`success/warning/priceUp/priceDown`).
  Метод `lerp` реализован (интерполяция для `AnimatedTheme`). Доступ:
  `Theme.of(context).extension<AppTokens>()!`, плюс удобный экстеншн `context.tokens`.
- **`app_theme.dart`** — `AppTheme.light()` / `AppTheme.dark()`:
  - `ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: ...)`;
  - `useMaterial3: true`;
  - `textTheme` из `app_typography`;
  - `extensions: [AppTokens.light]` / `[AppTokens.dark]`.
  Подключается в `app.dart`: `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`,
  `themeMode: ThemeMode.system`.

## 3. Каталог компонентов (`lib/shared/`)

Тонкая обёртка над M3-виджетами, потребляющая токены. Структура:
`lib/shared/components/` — по файлу на компонент + barrel-экспорт `components.dart`.
Каждый компонент: dartdoc-шапка; без хардкода (только токены / `ColorScheme` / `TextTheme`);
`const`-конструкторы где возможно; работает в обеих темах.

**Стартовый каталог (обязателен в фичах):**

| Компонент | Назначение |
|---|---|
| `AppButton` | варианты `primary/secondary/text/destructive`; состояния loading/disabled |
| `AppTextField` | поле ввода с лейблом/ошибкой/иконкой |
| `AppCard` | контейнер-карточка |
| `AppListTile` | строка списка (база для чеков/товаров) |
| `AppChip` | фильтры/категории |
| `AppBadge` | статусы (pending/processing/done/failed чека) |
| `AppScaffold` | каркас экрана с единым AppBar-паттерном |
| `AppEmptyState` | пустое состояние |
| `AppErrorView` | состояние ошибки |
| `AppLoader` | индикатор загрузки |
| `MoneyText` | **доменный** — форматирует суммы по валюте/локали |
| `PriceDeltaText` | **доменный** — цена ↑/↓ цветами `priceUp`/`priceDown` |

**Доменные композиты** (например `ReceiptListTile`, `BudgetProgressBar`) добавляются по мере
реализации фич, но строятся из каталога выше, а не с нуля.

**Что НЕ оборачиваем** (стоковый Material напрямую): разметка/структура —
`Row/Column/Stack/Padding/Expanded/Flexible/SizedBox/ListView/GridView/SingleChildScrollView`
и т.п. Каркас экрана — через `AppScaffold`.

## 4. Правила дизайн-системы

1. В `lib/features/**` UI-примитивы — **только из `shared/components/`**
   (`AppButton`, `AppTextField`, `AppCard`, `AppListTile`, `AppChip`, `AppBadge`, …).
   Прямые `ElevatedButton`/`FilledButton`/`TextButton`/`OutlinedButton`/`TextField`/
   `Card`/`ListTile`/`Chip` в фичах — запрещены.
2. Стоковый Material — **только для разметки** (см. §3 «Что НЕ оборачиваем»);
   каркас экрана — `AppScaffold`.
3. **Никакого хардкода** цвета/типографики/отступов/радиусов — только токены
   (`context.tokens`, `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`).
   Запрещены `Colors.*`, `Color(0x..)`, сырые `TextStyle(`, магические числа отступов/радиусов.
4. Новый компонент создаётся **только в `shared/`** и **только при повторе паттерна
   (≥2 использований)**; одноразовый UI — композиция существующих компонентов.
5. Каждый компонент обязан корректно работать в светлой и тёмной теме.

## 5. Документация и соблюдение

**Документация (источник истины):**
- Новый `docs/conventions/design-system.md`: каталог (компоненты, варианты/пропсы),
  токены, правила §4. Claude обращается к нему перед UI-работой.
- `app/CLAUDE.md` → секция «Дизайн-система» усиливается ссылкой и кратким сводом правил.
- Скилл `flutter-feature` → перед UI читать `design-system.md` и использовать каталог.

**Механическое соблюдение (автоматизация):**
- Хук `.claude/hooks/flutter-guards.sh` расширяется: помимо хардкода цвета/стиля —
  необблокирующее advisory при использовании в `lib/features/**` сырых Material-примитивов
  (`ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton`, `TextField`, `Card`,
  `ListTile`, `Chip`) с подсказкой shared-эквивалента. Остаётся exit 0 (не блокирует).
- Субагент `flutter-design-reviewer` дополняется: проверяет использование каталога `shared/`
  вместо сырых виджетов и что новые компоненты заведены в `shared/`, а не продублированы.

## 6. Зависимости

- Добавить в `app/pubspec.yaml`: `google_fonts` (Inter). Остальное — стоковый Flutter Material.
- `dart analyze` должен оставаться чистым; токены/компоненты покрываются виджет-тестами
  по мере необходимости (на этой итерации — минимально, т.к. логики фич нет).

## 7. Границы итерации (что НЕ делаем)

- Реальные экраны фич и их верстка.
- Бандлинг шрифта в assets (по умолчанию — runtime через `google_fonts`; бандл — позже при
  требовании офлайна).
- Доменные композиты конкретных фич (создаются в их собственных циклах).
