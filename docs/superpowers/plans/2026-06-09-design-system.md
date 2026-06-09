# Дизайн-система ChekiPrices — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать дизайн-систему Flutter-клиента: токены темы (M3 + бренд, светлая/тёмная), стартовый каталог переиспользуемых компонентов в `lib/shared/`, документацию-правила и автоматизацию их соблюдения. Без верстки реальных экранов фич.

**Architecture:** `lib/core/theme/` — единый источник токенов (`AppColors`, `AppTokens` через `ThemeExtension`, `AppTypography` на google_fonts/Inter, `AppTheme.light()/dark()` из `ColorScheme.fromSeed`). `lib/shared/components/` — тонкие обёртки над M3-виджетами, потребляющие токены. Правила фиксируются в `docs/conventions/design-system.md`, `app/CLAUDE.md`, хуке `flutter-guards.sh` и субагенте `flutter-design-reviewer`.

**Tech Stack:** Flutter 3.35 / Dart 3.9 (Material 3), google_fonts (Inter), intl (форматирование валют), flutter_test.

**Источник истины:** [docs/superpowers/specs/2026-06-09-design-system-design.md](../specs/2026-06-09-design-system-design.md). При расхождении — спек главнее.

**Важно об импортах:** имя пакета в `app/pubspec.yaml` — **`ticket_app`**. Все импорты внутри `app/` идут как `package:ticket_app/...`. Все команды выполняются из каталога `app/` (если не указано иное): `cd /Users/pablo/work/receipt-scan-app/app`.

**О TDD здесь:** логику (токены, `AppTokens.lerp`, форматирование сумм, направление дельты, поведение кнопки) пишем через failing-test → impl. Презентационные виджеты — лёгкий widget-тест на рендер и работу в обеих темах. Каждая задача завершается `dart analyze` (должно быть `No issues found!`) и `flutter test` нужного файла.

**О google_fonts в тестах:** в тестовой среде google_fonts не ходит в сеть и тихо падает на системный шрифт (печатает предупреждение, тест НЕ падает). Тесты темы не рендерят текст (только инспектируют `ThemeData`), поэтому шрифт не грузится. Если в каком-то окружении google_fonts начнёт кидать исключение — добавить в начало теста `GoogleFonts.config.allowRuntimeFetching = false;`.

---

## Карта файлов

**Создаём — тема (`app/lib/core/theme/`):**
- `app_colors.dart` — seed + семантические цвета (light/dark).
- `app_tokens.dart` — `AppTokens extends ThemeExtension<AppTokens>` + экстеншн `context.tokens`.
- `app_typography.dart` — `AppTypography.textTheme(...)` на google_fonts/Inter.
- `app_theme.dart` — `AppTheme.light()/dark()` (перезаписывает текущую заглушку).

**Создаём — компоненты (`app/lib/shared/components/`):**
- `app_button.dart`, `app_text_field.dart`, `app_card.dart`, `app_list_tile.dart`,
  `app_chip.dart`, `app_badge.dart`, `app_scaffold.dart`, `app_empty_state.dart`,
  `app_error_view.dart`, `app_loader.dart`, `money_text.dart`, `price_delta_text.dart`,
  `components.dart` (barrel).

**Создаём — тесты (`app/test/`):** зеркало `lib/` (см. задачи).

**Создаём/меняем — правила и автоматизация:**
- `docs/conventions/design-system.md` (новый).
- `app/CLAUDE.md` (усилить секцию «Дизайн-система»).
- `.claude/skills/flutter-feature/SKILL.md` (ссылка на design-system.md).
- `.claude/hooks/flutter-guards.sh` (advisory на сырые Material-примитивы).
- `.claude/agents/flutter-design-reviewer.md` (проверка каталога).

**Меняем — прочее:**
- `app/pubspec.yaml` (добавить `google_fonts`).
- `app/lib/app.dart` (подключить `theme`/`darkTheme`/`themeMode`).

---

## Task 1: Зависимости и тест-хелпер

**Files:**
- Modify: `app/pubspec.yaml`
- Create: `app/test/helpers/pump_component.dart`

- [ ] **Step 1: Добавить google_fonts**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub add google_fonts
```
Expected: `google_fonts` появляется в `dependencies` и `pubspec.lock`, `pub get` успешен.
Примечание: `intl` уже есть в зависимостях (`intl: any`) — повторно добавлять не нужно.

- [ ] **Step 2: Создать тест-хелпер**

Create `app/test/helpers/pump_component.dart`:

```dart
/// Назначение: хелпер для widget-тестов — оборачивает виджет в MaterialApp с темой приложения.
///
/// Слой: test/helpers
/// Зависимости: flutter_test, core/theme/app_theme.dart.
/// Ключевые типы: pumpComponent.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_theme.dart';

/// Рендерит [child] внутри MaterialApp со светлой или тёмной темой приложения.
Future<void> pumpComponent(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: child),
    ),
  );
}
```

> Этот файл импортирует `app_theme.dart`, который появится в Task 5. До этого момента `flutter test` хелпер не компилируется в одиночку — это нормально, он используется начиная с Task 8. `dart analyze` на этом шаге может показать неразрешённый импорт; он закроется после Task 5. Поэтому коммитим хелпер вместе с Task 5 либо допускаем временное предупреждение здесь.

- [ ] **Step 3: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/pubspec.yaml app/pubspec.lock app/test/helpers/pump_component.dart
git commit -m "chore(app): добавлен google_fonts; тест-хелпер pumpComponent

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `AppColors` — seed и семантические цвета

**Files:**
- Create: `app/lib/core/theme/app_colors.dart`
- Test: `app/test/core/theme/app_colors_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/core/theme/app_colors_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_colors.dart';

void main() {
  test('seed — emerald #2E7D5B', () {
    expect(AppColors.seed, const Color(0xFF2E7D5B));
  });

  test('семантические цвета заданы для light и dark', () {
    expect(AppColors.priceUpLight, isNot(AppColors.priceDownLight));
    expect(AppColors.priceUpDark, isNot(AppColors.priceDownDark));
    expect(AppColors.successLight, isA<Color>());
    expect(AppColors.warningDark, isA<Color>());
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_colors_test.dart`
Expected: ошибка компиляции — `app_colors.dart` не найден / `AppColors` не определён.

- [ ] **Step 3: Реализовать**

Create `app/lib/core/theme/app_colors.dart`:

```dart
/// Назначение: палитра-источник дизайн-системы — seed и семантические бренд-цвета.
///
/// Слой: core/theme
/// Зависимости: flutter material (Color).
/// Ключевые типы: AppColors.
library;

import 'package:flutter/material.dart';

/// Сырые цветовые константы дизайн-системы.
///
/// `ColorScheme` генерируется из [seed] (см. AppTheme). Семантические цвета,
/// которых нет в `ColorScheme`, заданы парами для светлой/тёмной темы и
/// прокидываются через `AppTokens`.
class AppColors {
  const AppColors._();

  /// Базовый цвет бренда (emerald) — из него строится палитра M3.
  static const Color seed = Color(0xFF2E7D5B);

  // --- light ---
  static const Color successLight = Color(0xFF2E7D32);
  static const Color warningLight = Color(0xFFB26A00);

  /// Цена выросла — «дороже» (красный).
  static const Color priceUpLight = Color(0xFFC62828);

  /// Цена снизилась — «выгоднее» (зелёный).
  static const Color priceDownLight = Color(0xFF2E7D32);

  // --- dark ---
  static const Color successDark = Color(0xFF81C784);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color priceUpDark = Color(0xFFEF9A9A);
  static const Color priceDownDark = Color(0xFFA5D6A7);
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_colors_test.dart && dart analyze lib/core/theme`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/theme/app_colors.dart app/test/core/theme/app_colors_test.dart
git commit -m "feat(theme): AppColors — seed и семантические цвета

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: `AppTokens` (ThemeExtension) + `context.tokens`

**Files:**
- Create: `app/lib/core/theme/app_tokens.dart`
- Test: `app/test/core/theme/app_tokens_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/core/theme/app_tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_colors.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';

void main() {
  test('шкала spacing и radii', () {
    const t = AppTokens.light;
    expect(t.spaceXs, 4);
    expect(t.spaceMd, 12);
    expect(t.spaceXxl, 32);
    expect(t.radiusMd, 12);
    expect(t.radiusPill, 999);
  });

  test('семантические цвета берутся из AppColors по теме', () {
    expect(AppTokens.light.priceUp, AppColors.priceUpLight);
    expect(AppTokens.dark.priceUp, AppColors.priceUpDark);
  });

  test('lerp при t=0 возвращает исходные цвета', () {
    final r = AppTokens.light.lerp(AppTokens.dark, 0);
    expect(r.priceUp, AppColors.priceUpLight);
    expect(r.spaceMd, 12);
  });

  test('lerp при t=1 возвращает целевые цвета', () {
    final r = AppTokens.light.lerp(AppTokens.dark, 1);
    expect(r.priceUp, AppColors.priceUpDark);
  });

  testWidgets('context.tokens достаёт расширение из темы', (tester) async {
    late AppTokens captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Builder(
          builder: (context) {
            captured = context.tokens;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.spaceMd, 12);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_tokens_test.dart`
Expected: ошибка компиляции — `app_tokens.dart` не найден.

- [ ] **Step 3: Реализовать**

Create `app/lib/core/theme/app_tokens.dart`:

```dart
/// Назначение: дизайн-токены приложения (spacing, radii, durations, семантические цвета)
/// как ThemeExtension, прикрепляемый к ThemeData.
///
/// Слой: core/theme
/// Зависимости: flutter material, dart:ui (lerpDouble), core/theme/app_colors.dart.
/// Ключевые типы: AppTokens, AppTokensX (context.tokens).
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Иммутабельный набор дизайн-токенов, доступный через `Theme.of(context)`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
    required this.durationFast,
    required this.durationNormal,
    required this.success,
    required this.warning,
    required this.priceUp,
    required this.priceDown,
  });

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusPill;

  final Duration durationFast;
  final Duration durationNormal;

  final Color success;
  final Color warning;
  final Color priceUp;
  final Color priceDown;

  /// Токены светлой темы.
  static const AppTokens light = AppTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusPill: 999,
    durationFast: Duration(milliseconds: 150),
    durationNormal: Duration(milliseconds: 250),
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    priceUp: AppColors.priceUpLight,
    priceDown: AppColors.priceDownLight,
  );

  /// Токены тёмной темы (размеры те же, цвета — тёмные варианты).
  static const AppTokens dark = AppTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusPill: 999,
    durationFast: Duration(milliseconds: 150),
    durationNormal: Duration(milliseconds: 250),
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    priceUp: AppColors.priceUpDark,
    priceDown: AppColors.priceDownDark,
  );

  @override
  AppTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
    Duration? durationFast,
    Duration? durationNormal,
    Color? success,
    Color? warning,
    Color? priceUp,
    Color? priceDown,
  }) {
    return AppTokens(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
      durationFast: durationFast ?? this.durationFast,
      durationNormal: durationNormal ?? this.durationNormal,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      priceUp: priceUp ?? this.priceUp,
      priceDown: priceDown ?? this.priceDown,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
      spaceXxl: lerpDouble(spaceXxl, other.spaceXxl, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      durationFast: t < 0.5 ? durationFast : other.durationFast,
      durationNormal: t < 0.5 ? durationNormal : other.durationNormal,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      priceUp: Color.lerp(priceUp, other.priceUp, t)!,
      priceDown: Color.lerp(priceDown, other.priceDown, t)!,
    );
  }
}

/// Удобный доступ к токенам: `context.tokens.spaceMd`.
extension AppTokensX on BuildContext {
  /// Дизайн-токены текущей темы.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_tokens_test.dart && dart analyze lib/core/theme`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/theme/app_tokens.dart app/test/core/theme/app_tokens_test.dart
git commit -m "feat(theme): AppTokens (ThemeExtension) + context.tokens

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: `AppTypography` (Inter через google_fonts)

**Files:**
- Create: `app/lib/core/theme/app_typography.dart`
- Test: `app/test/core/theme/app_typography_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/core/theme/app_typography_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_typography.dart';

void main() {
  test('textTheme возвращает заполненную типографику на базе исходной', () {
    const base = Typography.englishLike2021;
    final theme = AppTypography.textTheme(base);
    expect(theme.bodyMedium, isNotNull);
    expect(theme.titleLarge, isNotNull);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_typography_test.dart`
Expected: ошибка компиляции — `app_typography.dart` не найден.

- [ ] **Step 3: Реализовать**

Create `app/lib/core/theme/app_typography.dart`:

```dart
/// Назначение: типографика дизайн-системы — шрифт Inter поверх M3 TextTheme.
///
/// Слой: core/theme
/// Зависимости: flutter material, google_fonts.
/// Ключевые типы: AppTypography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Фабрика TextTheme приложения.
class AppTypography {
  const AppTypography._();

  /// Применяет шрифт Inter к [base] (типографической шкале M3).
  static TextTheme textTheme(TextTheme base) => GoogleFonts.interTextTheme(base);
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_typography_test.dart && dart analyze lib/core/theme`
Expected: тест PASS (возможна строка-предупреждение google_fonts о сети — это не ошибка); `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/theme/app_typography.dart app/test/core/theme/app_typography_test.dart
git commit -m "feat(theme): AppTypography (Inter через google_fonts)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: `AppTheme.light()/dark()` + подключение в `app.dart`

**Files:**
- Modify (перезаписать): `app/lib/core/theme/app_theme.dart`
- Modify: `app/lib/app.dart`
- Test: `app/test/core/theme/app_theme_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/core/theme/app_theme_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_theme.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';

void main() {
  test('светлая тема: M3, brightness light, токены прикреплены', () {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.extension<AppTokens>(), isNotNull);
    expect(theme.extension<AppTokens>()!.priceUp, AppTokens.light.priceUp);
  });

  test('тёмная тема: brightness dark, тёмные токены', () {
    final theme = AppTheme.dark();
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.extension<AppTokens>()!.priceUp, AppTokens.dark.priceUp);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_theme_test.dart`
Expected: падение — текущая заглушка `AppTheme` имеет только `light()` без `extension<AppTokens>()` (тест на токены/`dark()` падает).

- [ ] **Step 3: Реализовать — перезаписать `app_theme.dart`**

Overwrite `app/lib/core/theme/app_theme.dart`:

```dart
/// Назначение: тема приложения — ThemeData для светлого и тёмного режимов на основе
/// seed-цвета (M3), с типографикой Inter и прикреплёнными дизайн-токенами.
///
/// Слой: core/theme
/// Зависимости: flutter material, core/theme/{app_colors,app_tokens,app_typography}.dart.
/// Ключевые типы: AppTheme.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Фабрики тем приложения.
class AppTheme {
  const AppTheme._();

  /// Светлая тема.
  static ThemeData light() => _build(Brightness.light, AppTokens.light);

  /// Тёмная тема.
  static ThemeData dark() => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens tokens) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
```

- [ ] **Step 4: Подключить тему в `app.dart`**

Replace the `MaterialApp.router` call in `app/lib/app.dart` so it wires both themes. The full updated build method:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'ChekiPrices',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
```

(Импорт `import 'core/theme/app_theme.dart';` в `app.dart` уже есть — оставить.)

- [ ] **Step 5: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/core/theme/app_theme_test.dart && dart analyze lib`
Expected: тесты PASS; `No issues found!` (в т.ч. `pump_component.dart` из Task 1 теперь компилируется).

- [ ] **Step 6: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/theme/app_theme.dart app/lib/app.dart app/test/core/theme/app_theme_test.dart
git commit -m "feat(theme): AppTheme.light()/dark() из seed + подключение в app.dart

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: `MoneyText` — форматирование сумм (доменный компонент)

**Files:**
- Create: `app/lib/shared/components/money_text.dart`
- Test: `app/test/shared/components/money_text_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/shared/components/money_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/money_text.dart';

import '../../helpers/pump_component.dart';

void main() {
  test('format USD/en_US даёт привычный вид', () {
    expect(
      MoneyText.format(1234.5, currencyCode: 'USD', locale: 'en_US'),
      r'$1,234.50',
    );
  });

  test('format RUB/ru содержит символ рубля', () {
    final s = MoneyText.format(1234.5, currencyCode: 'RUB', locale: 'ru');
    expect(s.contains('₽'), isTrue);
  });

  testWidgets('рендерит отформатированную сумму', (tester) async {
    await pumpComponent(
      tester,
      const MoneyText(1234.5, currencyCode: 'USD', locale: 'en_US'),
    );
    expect(find.text(r'$1,234.50'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/money_text_test.dart`
Expected: ошибка компиляции — `money_text.dart` не найден.

- [ ] **Step 3: Реализовать**

Create `app/lib/shared/components/money_text.dart`:

```dart
/// Назначение: отображение денежной суммы по валюте/локали (доменный компонент).
///
/// Слой: shared/components
/// Зависимости: flutter material, intl (NumberFormat).
/// Ключевые типы: MoneyText.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Текст с денежной суммой, отформатированной по [currencyCode] и локали.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    required this.currencyCode,
    this.locale,
    this.style,
    super.key,
  });

  /// Сумма.
  final num amount;

  /// Код валюты (ISO 4217), напр. `RUB`, `USD`.
  final String currencyCode;

  /// Локаль форматирования; по умолчанию — локаль контекста.
  final String? locale;

  /// Переопределение стиля; по умолчанию — `textTheme.bodyMedium`.
  final TextStyle? style;

  /// Чистая функция форматирования (тестируется отдельно от виджета).
  static String format(
    num amount, {
    required String currencyCode,
    String? locale,
  }) {
    return NumberFormat.simpleCurrency(locale: locale, name: currencyCode)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final loc = locale ?? Localizations.localeOf(context).toString();
    return Text(
      format(amount, currencyCode: currencyCode, locale: loc),
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/money_text_test.dart && dart analyze lib/shared`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/money_text.dart app/test/shared/components/money_text_test.dart
git commit -m "feat(shared): MoneyText — форматирование сумм по валюте

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: `PriceDeltaText` — дельта цены (доменный компонент)

**Files:**
- Create: `app/lib/shared/components/price_delta_text.dart`
- Test: `app/test/shared/components/price_delta_text_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/shared/components/price_delta_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';
import 'package:ticket_app/shared/components/price_delta_text.dart';

import '../../helpers/pump_component.dart';

void main() {
  test('directionOf по знаку дельты', () {
    expect(PriceDeltaText.directionOf(5), PriceDirection.up);
    expect(PriceDeltaText.directionOf(-5), PriceDirection.down);
    expect(PriceDeltaText.directionOf(0), PriceDirection.flat);
  });

  testWidgets('рост цены красит текст в priceUp', (tester) async {
    await pumpComponent(
      tester,
      const PriceDeltaText(delta: 10, currencyCode: 'USD', locale: 'en_US'),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppTokens.light.priceUp);
  });

  testWidgets('снижение цены красит текст в priceDown', (tester) async {
    await pumpComponent(
      tester,
      const PriceDeltaText(delta: -10, currencyCode: 'USD', locale: 'en_US'),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppTokens.light.priceDown);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/price_delta_text_test.dart`
Expected: ошибка компиляции — `price_delta_text.dart` не найден.

- [ ] **Step 3: Реализовать**

Create `app/lib/shared/components/price_delta_text.dart`:

```dart
/// Назначение: отображение изменения цены со стрелкой и цветом (доменный компонент).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart, shared/components/money_text.dart.
/// Ключевые типы: PriceDeltaText, PriceDirection.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'money_text.dart';

/// Направление изменения цены.
enum PriceDirection { up, down, flat }

/// Текст изменения цены: стрелка + абсолютная величина, окрашенные по направлению.
class PriceDeltaText extends StatelessWidget {
  const PriceDeltaText({
    required this.delta,
    required this.currencyCode,
    this.locale,
    super.key,
  });

  /// Изменение цены (текущая − эталонная).
  final num delta;

  /// Код валюты.
  final String currencyCode;

  /// Локаль; по умолчанию — локаль контекста.
  final String? locale;

  /// Направление по знаку дельты (чистая функция).
  static PriceDirection directionOf(num delta) {
    if (delta > 0) return PriceDirection.up;
    if (delta < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final direction = directionOf(delta);
    final color = switch (direction) {
      PriceDirection.up => tokens.priceUp,
      PriceDirection.down => tokens.priceDown,
      PriceDirection.flat => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final icon = switch (direction) {
      PriceDirection.up => Icons.arrow_upward,
      PriceDirection.down => Icons.arrow_downward,
      PriceDirection.flat => Icons.remove,
    };
    final loc = locale ?? Localizations.localeOf(context).toString();
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: tokens.spaceXs),
        Text(
          MoneyText.format(delta.abs(), currencyCode: currencyCode, locale: loc),
          style: style,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/price_delta_text_test.dart && dart analyze lib/shared`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/price_delta_text.dart app/test/shared/components/price_delta_text_test.dart
git commit -m "feat(shared): PriceDeltaText — дельта цены со стрелкой и цветом

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: `AppButton`

**Files:**
- Create: `app/lib/shared/components/app_button.dart`
- Test: `app/test/shared/components/app_button_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/shared/components/app_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_button.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('primary: показывает лейбл и вызывает onPressed', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'Сохранить', onPressed: () => taps++),
    );
    expect(find.text('Сохранить'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('loading: показывает индикатор и не вызывает onPressed', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppButton(label: 'Сохранить', loading: true, onPressed: () => taps++),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('рендерится в тёмной теме', (tester) async {
    await pumpComponent(
      tester,
      AppButton(label: 'Ок', onPressed: () {}),
      brightness: Brightness.dark,
    );
    expect(find.text('Ок'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_button_test.dart`
Expected: ошибка компиляции — `app_button.dart` не найден.

- [ ] **Step 3: Реализовать**

Create `app/lib/shared/components/app_button.dart`:

```dart
/// Назначение: кнопка дизайн-системы с вариантами и состоянием загрузки.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppButton, AppButtonVariant.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Визуальный вариант [AppButton].
enum AppButtonVariant { primary, secondary, text, destructive }

/// Кнопка дизайн-системы. Оборачивает M3-кнопки, единый радиус из токенов.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Растягивать ли кнопку по ширине родителя.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = loading ? null : onPressed;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
    );

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
          )
        : _label(context);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            shape: shape,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _label(BuildContext context) {
    if (icon == null) return Text(label);
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        SizedBox(width: tokens.spaceSm),
        Text(label),
      ],
    );
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_button_test.dart && dart analyze lib/shared`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 5: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/app_button.dart app/test/shared/components/app_button_test.dart
git commit -m "feat(shared): AppButton (варианты + loading)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: `AppCard`, `AppTextField`

**Files:**
- Create: `app/lib/shared/components/app_card.dart`
- Create: `app/lib/shared/components/app_text_field.dart`
- Test: `app/test/shared/components/app_card_test.dart`
- Test: `app/test/shared/components/app_text_field_test.dart`

- [ ] **Step 1: Написать падающие тесты**

Create `app/test/shared/components/app_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_card.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает child и реагирует на тап', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppCard(onTap: () => taps++, child: const Text('Контент')),
    );
    expect(find.text('Контент'), findsOneWidget);
    await tester.tap(find.text('Контент'));
    await tester.pump();
    expect(taps, 1);
  });
}
```

Create `app/test/shared/components/app_text_field_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_text_field.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает label и отдаёт ввод через onChanged', (tester) async {
    String? value;
    await pumpComponent(
      tester,
      AppTextField(label: 'Email', onChanged: (v) => value = v),
    );
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.c');
    expect(value, 'a@b.c');
  });

  testWidgets('показывает текст ошибки', (tester) async {
    await pumpComponent(
      tester,
      const AppTextField(label: 'Email', errorText: 'Неверный email'),
    );
    expect(find.text('Неверный email'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падают**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_card_test.dart test/shared/components/app_text_field_test.dart`
Expected: ошибки компиляции — файлы не найдены.

- [ ] **Step 3: Реализовать `app_card.dart`**

Create `app/lib/shared/components/app_card.dart`:

```dart
/// Назначение: карточка-контейнер дизайн-системы (единый радиус/отступы из токенов).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppCard.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Карточка с единым скруглением и внутренним отступом; опционально кликабельна.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(tokens.radiusLg);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(tokens.spaceLg),
      child: child,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
```

- [ ] **Step 4: Реализовать `app_text_field.dart`**

Create `app/lib/shared/components/app_text_field.dart`:

```dart
/// Назначение: текстовое поле дизайн-системы с лейблом, ошибкой и иконкой.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppTextField.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Поле ввода с единым оформлением (M3 outlined).
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.onChanged,
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Запустить — убедиться, что проходят**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_card_test.dart test/shared/components/app_text_field_test.dart && dart analyze lib/shared`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 6: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/app_card.dart app/lib/shared/components/app_text_field.dart app/test/shared/components/app_card_test.dart app/test/shared/components/app_text_field_test.dart
git commit -m "feat(shared): AppCard и AppTextField

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: `AppListTile`, `AppChip`, `AppBadge`

**Files:**
- Create: `app/lib/shared/components/app_list_tile.dart`
- Create: `app/lib/shared/components/app_chip.dart`
- Create: `app/lib/shared/components/app_badge.dart`
- Test: `app/test/shared/components/app_list_tile_test.dart`
- Test: `app/test/shared/components/app_chip_test.dart`
- Test: `app/test/shared/components/app_badge_test.dart`

- [ ] **Step 1: Написать падающие тесты**

Create `app/test/shared/components/app_list_tile_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_list_tile.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает title/subtitle и реагирует на тап', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppListTile(title: 'Чек №1', subtitle: 'Магазин', onTap: () => taps++),
    );
    expect(find.text('Чек №1'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
    await tester.tap(find.text('Чек №1'));
    await tester.pump();
    expect(taps, 1);
  });
}
```

Create `app/test/shared/components/app_chip_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_chip.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает label и переключает выбор', (tester) async {
    bool? selected;
    await pumpComponent(
      tester,
      AppChip(
        label: 'Продукты',
        selected: false,
        onSelected: (v) => selected = v,
      ),
    );
    expect(find.text('Продукты'), findsOneWidget);
    await tester.tap(find.text('Продукты'));
    await tester.pump();
    expect(selected, isTrue);
  });
}
```

Create `app/test/shared/components/app_badge_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';
import 'package:ticket_app/shared/components/app_badge.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('success-бейдж показывает текст и красится в success', (tester) async {
    await pumpComponent(
      tester,
      const AppBadge(label: 'Готов', tone: AppBadgeTone.success),
    );
    expect(find.text('Готов'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(AppBadge), matching: find.byType(Container)),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, AppTokens.light.success);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падают**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_list_tile_test.dart test/shared/components/app_chip_test.dart test/shared/components/app_badge_test.dart`
Expected: ошибки компиляции — файлы не найдены.

- [ ] **Step 3: Реализовать `app_list_tile.dart`**

Create `app/lib/shared/components/app_list_tile.dart`:

```dart
/// Назначение: строка списка дизайн-системы (основа для списков чеков/товаров).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppListTile.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Строка списка с единым скруглением и опциональными ведущим/замыкающим виджетами.
class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListTile(
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    );
  }
}
```

- [ ] **Step 4: Реализовать `app_chip.dart`**

Create `app/lib/shared/components/app_chip.dart`:

```dart
/// Назначение: чип-фильтр дизайн-системы (категории/фильтры).
///
/// Слой: shared/components
/// Зависимости: flutter material.
/// Ключевые типы: AppChip.
library;

import 'package:flutter/material.dart';

/// Выбираемый чип на основе M3 FilterChip.
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}
```

- [ ] **Step 5: Реализовать `app_badge.dart`**

Create `app/lib/shared/components/app_badge.dart`:

```dart
/// Назначение: бейдж-статус дизайн-системы (статусы чека и т.п.).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppBadge, AppBadgeTone.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Тональность бейджа.
enum AppBadgeTone { neutral, success, warning, error }

/// Небольшой цветной бейдж с подписью.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.neutral,
    super.key,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final bg = switch (tone) {
      AppBadgeTone.neutral => scheme.surfaceContainerHighest,
      AppBadgeTone.success => tokens.success,
      AppBadgeTone.warning => tokens.warning,
      AppBadgeTone.error => scheme.errorContainer,
    };
    final fg = switch (tone) {
      AppBadgeTone.neutral => scheme.onSurfaceVariant,
      AppBadgeTone.error => scheme.onErrorContainer,
      _ => Colors.white,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
```

> Примечание: `Colors.white` здесь — намеренный контрастный текст на насыщенном
> цветном фоне бейджа внутри компонента дизайн-системы (`shared/`), что правилами
> разрешено (запрет хардкода действует для `lib/features/**`). Хук advisory может
> предупредить — это допустимое исключение для компонента каталога.

- [ ] **Step 6: Запустить — убедиться, что проходят**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/app_list_tile_test.dart test/shared/components/app_chip_test.dart test/shared/components/app_badge_test.dart && dart analyze lib/shared`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 7: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/app_list_tile.dart app/lib/shared/components/app_chip.dart app/lib/shared/components/app_badge.dart app/test/shared/components/app_list_tile_test.dart app/test/shared/components/app_chip_test.dart app/test/shared/components/app_badge_test.dart
git commit -m "feat(shared): AppListTile, AppChip, AppBadge

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: `AppScaffold`, `AppLoader`, `AppEmptyState`, `AppErrorView` + barrel

**Files:**
- Create: `app/lib/shared/components/app_scaffold.dart`
- Create: `app/lib/shared/components/app_loader.dart`
- Create: `app/lib/shared/components/app_empty_state.dart`
- Create: `app/lib/shared/components/app_error_view.dart`
- Create: `app/lib/shared/components/components.dart` (barrel)
- Test: `app/test/shared/components/state_widgets_test.dart`

- [ ] **Step 1: Написать падающий тест**

Create `app/test/shared/components/state_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/components.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('AppScaffold показывает заголовок и body', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(title: 'Чеки', body: Text('Список')),
      ),
    );
    expect(find.text('Чеки'), findsOneWidget);
    expect(find.text('Список'), findsOneWidget);
  });

  testWidgets('AppLoader показывает индикатор', (tester) async {
    await pumpComponent(tester, const AppLoader());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppEmptyState показывает сообщение', (tester) async {
    await pumpComponent(tester, const AppEmptyState(message: 'Пусто'));
    expect(find.text('Пусто'), findsOneWidget);
  });

  testWidgets('AppErrorView показывает ошибку и кнопку повтора', (tester) async {
    var retried = 0;
    await pumpComponent(
      tester,
      AppErrorView(message: 'Ошибка', onRetry: () => retried++),
    );
    expect(find.text('Ошибка'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(retried, 1);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/state_widgets_test.dart`
Expected: ошибка компиляции — `components.dart` и компоненты не найдены.

- [ ] **Step 3: Реализовать `app_scaffold.dart`**

Create `app/lib/shared/components/app_scaffold.dart`:

```dart
/// Назначение: каркас экрана дизайн-системы (единый AppBar-паттерн).
///
/// Слой: shared/components
/// Зависимости: flutter material.
/// Ключевые типы: AppScaffold.
library;

import 'package:flutter/material.dart';

/// Каркас экрана с заголовком, опциональными действиями и FAB.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
```

- [ ] **Step 4: Реализовать `app_loader.dart`**

Create `app/lib/shared/components/app_loader.dart`:

```dart
/// Назначение: индикатор загрузки дизайн-системы (по центру).
///
/// Слой: shared/components
/// Зависимости: flutter material.
/// Ключевые типы: AppLoader.
library;

import 'package:flutter/material.dart';

/// Центрированный индикатор загрузки.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
```

- [ ] **Step 5: Реализовать `app_empty_state.dart`**

Create `app/lib/shared/components/app_empty_state.dart`:

```dart
/// Назначение: пустое состояние дизайн-системы (нет данных).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppEmptyState.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Заглушка «нет данных» с иконкой и сообщением.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            SizedBox(height: tokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Реализовать `app_error_view.dart`**

Create `app/lib/shared/components/app_error_view.dart`:

```dart
/// Назначение: состояние ошибки дизайн-системы с кнопкой повтора.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart, shared/components/app_button.dart.
/// Ключевые типы: AppErrorView.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'app_button.dart';

/// Экран ошибки: сообщение + опциональная кнопка «Повторить».
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    required this.message,
    this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            SizedBox(height: tokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              SizedBox(height: tokens.spaceLg),
              AppButton(
                label: 'Повторить',
                variant: AppButtonVariant.secondary,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Создать barrel `components.dart`**

Create `app/lib/shared/components/components.dart`:

```dart
/// Назначение: единая точка импорта компонентов дизайн-системы.
///
/// Слой: shared/components
/// Зависимости: реэкспорт компонентов каталога.
/// Ключевые типы: реэкспорт.
library;

export 'app_badge.dart';
export 'app_button.dart';
export 'app_card.dart';
export 'app_chip.dart';
export 'app_empty_state.dart';
export 'app_error_view.dart';
export 'app_list_tile.dart';
export 'app_loader.dart';
export 'app_scaffold.dart';
export 'app_text_field.dart';
export 'money_text.dart';
export 'price_delta_text.dart';
```

- [ ] **Step 8: Запустить — убедиться, что проходит**

Run: `cd /Users/pablo/work/receipt-scan-app/app && flutter test test/shared/components/state_widgets_test.dart && dart analyze lib`
Expected: тесты PASS; `No issues found!`.

- [ ] **Step 9: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/shared/components/app_scaffold.dart app/lib/shared/components/app_loader.dart app/lib/shared/components/app_empty_state.dart app/lib/shared/components/app_error_view.dart app/lib/shared/components/components.dart app/test/shared/components/state_widgets_test.dart
git commit -m "feat(shared): AppScaffold, AppLoader, AppEmptyState, AppErrorView + barrel

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Документ `docs/conventions/design-system.md`

**Files:**
- Create: `docs/conventions/design-system.md`

- [ ] **Step 1: Создать документ**

Create `docs/conventions/design-system.md`:

```markdown
# Дизайн-система ChekiPrices

Источник истины по UI. Перед версткой экранов читай этот файл и используй каталог
компонентов из `app/lib/shared/components/`. Полный дизайн — `../superpowers/specs/2026-06-09-design-system-design.md`.

## Принцип

Material 3 + собственный бренд: стоковые M3-виджеты, единый слой токенов и тонкий
каталог компонентов. Светлая и тёмная темы из одного seed-цвета.

## Токены (`app/lib/core/theme/`)

- **Цвета:** палитра — `ColorScheme.fromSeed(AppColors.seed)` (seed `#2E7D5B`).
  Семантические бренд-цвета — в `AppTokens`: `success`, `warning`, `priceUp`, `priceDown`.
- **Типографика:** Inter через `AppTypography` (google_fonts).
- **Размеры/прочее:** `AppTokens` (ThemeExtension): spacing (`spaceXs..spaceXxl` = 4/8/12/16/24/32),
  radii (`radiusSm/Md/Lg/Pill` = 8/12/16/999), durations (`durationFast/Normal`).
- **Доступ:** `context.tokens.spaceMd`, `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`.

## Каталог компонентов (`app/lib/shared/components/`)

Импорт: `import 'package:ticket_app/shared/components/components.dart';`

| Компонент | Назначение |
|---|---|
| `AppButton` | Кнопка; варианты `primary/secondary/text/destructive`, `loading`, `icon`, `expanded`. |
| `AppTextField` | Поле ввода; `label`, `errorText`, `prefixIcon`, `obscureText`. |
| `AppCard` | Карточка-контейнер; опционально `onTap`. |
| `AppListTile` | Строка списка; `title/subtitle/leading/trailing/onTap`. |
| `AppChip` | Фильтр-чип; `selected`, `onSelected`. |
| `AppBadge` | Бейдж-статус; `tone` (`neutral/success/warning/error`). |
| `AppScaffold` | Каркас экрана; `title`, `body`, `actions`, `floatingActionButton`. |
| `AppLoader` | Индикатор загрузки. |
| `AppEmptyState` | Пустое состояние; `message`, `icon`. |
| `AppErrorView` | Ошибка; `message`, `onRetry`. |
| `MoneyText` | Сумма по валюте/локали (доменный). |
| `PriceDeltaText` | Изменение цены ↑/↓ цветом (доменный). |

## Правила (ОБЯЗАТЕЛЬНО)

1. В `lib/features/**` UI-примитивы — **только из каталога** (`AppButton`, `AppTextField`,
   `AppCard`, `AppListTile`, `AppChip`, `AppBadge`, …). Прямые `ElevatedButton`/`FilledButton`/
   `TextButton`/`OutlinedButton`/`TextField`/`Card`/`ListTile`/`Chip` — запрещены.
2. Стоковый Material — только для разметки (`Row/Column/Stack/Padding/Expanded/SizedBox/
   ListView/GridView/...`); каркас экрана — `AppScaffold`.
3. **Никакого хардкода** цвета/типографики/отступов/радиусов — только токены. Запрещены
   `Colors.*`, `Color(0x..)`, сырые `TextStyle(`, магические числа отступов/радиусов.
4. Новый компонент — **только в `shared/components/`** и только при повторе паттерна
   (≥2 использований); одноразовый UI — композиция существующих.
5. Компонент обязан работать в светлой и тёмной теме.

## Расширение каталога

Новый компонент: файл в `shared/components/` с dartdoc-шапкой, реэкспорт в `components.dart`,
widget-тест (рендер + работа в обеих темах), обновление таблицы выше.
```

- [ ] **Step 2: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add docs/conventions/design-system.md
git commit -m "docs: conventions/design-system.md — токены, каталог, правила

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Усилить `app/CLAUDE.md` и скилл `flutter-feature`

**Files:**
- Modify: `app/CLAUDE.md`
- Modify: `.claude/skills/flutter-feature/SKILL.md`

- [ ] **Step 1: Обновить секцию «Дизайн-система» в `app/CLAUDE.md`**

В `app/CLAUDE.md` найти блок, начинающийся со строки `## Дизайн-система (правила)`, и
заменить его пунктами-ссылками на каталог (остальной текст файла не трогать). Новый блок:

```markdown
## Дизайн-система (правила)

Полные правила и каталог — `../docs/conventions/design-system.md`. Кратко:

- **Единая тема** в `lib/core/theme/` (`AppTheme.light()/dark()`, `ColorScheme.fromSeed`,
  Inter, `AppTokens` через `ThemeExtension`). Доступ: `context.tokens`, `colorScheme`, `textTheme`.
- **Каталог компонентов** — `lib/shared/components/` (импорт `components.dart`).
  В `lib/features/**` UI-примитивы берём ТОЛЬКО из каталога (`AppButton`, `AppTextField`,
  `AppCard`, `AppListTile`, `AppChip`, `AppBadge`, `AppScaffold`, `AppEmptyState`,
  `AppErrorView`, `AppLoader`, `MoneyText`, `PriceDeltaText`).
- **Запрещено в фичах:** прямые `ElevatedButton/FilledButton/TextButton/OutlinedButton/
  TextField/Card/ListTile/Chip`; `Colors.*`, `Color(0x..)`, сырые `TextStyle(`, магические
  отступы/радиусы. Стоковый Material — только для разметки.
- **Новый компонент** — только в `shared/components/` и только при повторе паттерна (≥2);
  одноразовое — композиция существующих. (Напоминания включены хуком `flutter-guards`.)
- UI обязан работать в light/dark.
- Перенос макетов из Figma — через `figma-generate-design`/`figma-code-connect` с привязкой
  к токенам, а не пиксельным хардкодом.
```

- [ ] **Step 2: Обновить скилл `flutter-feature`**

В `.claude/skills/flutter-feature/SKILL.md` найти строку в «Шаг 0» про чтение контекста и
добавить пункт про дизайн-систему. Заменить пункт 2 «Шага 0» на:

```markdown
2. `app/CLAUDE.md`, `docs/conventions/flutter.md` и **`docs/conventions/design-system.md`** —
   слои, зависимости, codegen, именование И каталог компонентов/правила дизайн-системы.
   UI в фиче собираем из `lib/shared/components/`, а не из сырых Material-виджетов.
```

- [ ] **Step 3: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/CLAUDE.md .claude/skills/flutter-feature/SKILL.md
git commit -m "docs: правила дизайн-системы в app/CLAUDE.md и flutter-feature

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Расширить хук `flutter-guards.sh`

**Files:**
- Modify: `.claude/hooks/flutter-guards.sh`

- [ ] **Step 1: Добавить advisory на сырые Material-примитивы**

В `.claude/hooks/flutter-guards.sh` найти блок дизайн-системы (ветку `*/lib/features/*.dart`)
и расширить его: помимо хардкода цвета — предупреждать о сырых Material-примитивах. Заменить
существующий `case "$f"` для design-ветки на:

```bash
case "$f" in
  */lib/features/*.dart)
    if [ -f "$f" ] && grep -nE 'Color\(0x|Colors\.[a-z]|TextStyle\(' "$f" >/dev/null 2>&1; then
      msg="Дизайн-система: в $f обнаружен хардкод цвета/стиля. Используйте токены темы (lib/core/theme/, Theme.of(context).colorScheme / .textTheme, ThemeExtension) вместо Colors.*, Color(0x..) и сырых TextStyle(. См. app/CLAUDE.md → «Дизайн-система»."
    elif [ -f "$f" ] && grep -nE '\b(ElevatedButton|FilledButton|TextButton|OutlinedButton|TextField|Card|ListTile|FilterChip|Chip)\(' "$f" >/dev/null 2>&1; then
      msg="Дизайн-система: в $f используется сырой Material-примитив. В lib/features/** берите компоненты из каталога lib/shared/components/ (AppButton, AppTextField, AppCard, AppListTile, AppChip, ...). См. docs/conventions/design-system.md."
    fi
    ;;
esac
```

(Ветка приватности `*/worker/src/Privacy/*|...` остаётся без изменений.)

- [ ] **Step 2: Проверить хук на образцах**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app
mkdir -p app/lib/features/_t/presentation
printf 'import "x";\nfinal w = ElevatedButton(onPressed: null, child: Text("x"));\n' > app/lib/features/_t/presentation/t.dart
echo '{"tool_name":"Edit","tool_input":{"file_path":"app/lib/features/_t/presentation/t.dart"}}' | .claude/hooks/flutter-guards.sh
rm -rf app/lib/features/_t
```
Expected: JSON с `additionalContext`, упоминающим каталог `lib/shared/components/` (advisory по сырому `ElevatedButton`). Exit 0.

- [ ] **Step 3: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add .claude/hooks/flutter-guards.sh
git commit -m "chore(hooks): flutter-guards — advisory на сырые Material-примитивы в фичах

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Дополнить субагента `flutter-design-reviewer`

**Files:**
- Modify: `.claude/agents/flutter-design-reviewer.md`

- [ ] **Step 1: Добавить проверку каталога в раздел «1. Дизайн-система»**

В `.claude/agents/flutter-design-reviewer.md` в разделе «### 1. Дизайн-система (главное)»
добавить в конец списка два пункта:

```markdown
- **Каталог обязателен:** в `lib/features/**` UI-примитивы — только из
  `lib/shared/components/` (`AppButton`, `AppTextField`, `AppCard`, `AppListTile`,
  `AppChip`, `AppBadge`, `AppScaffold`, `AppEmptyState`, `AppErrorView`, `AppLoader`,
  `MoneyText`, `PriceDeltaText`). Прямые `ElevatedButton/FilledButton/TextButton/
  OutlinedButton/TextField/Card/ListTile/Chip` в фичах — нарушение.
- **Новые компоненты** заводятся в `shared/components/` (с реэкспортом в `components.dart`
  и widget-тестом), а не дублируются bespoke-версткой в фиче. Источник правил —
  `docs/conventions/design-system.md`.
```

- [ ] **Step 2: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add .claude/agents/flutter-design-reviewer.md
git commit -m "chore(agents): flutter-design-reviewer — проверка каталога shared/

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 16: Финальная верификация и завершение

**Files:**
- Verify: весь `app/` и `.claude/`

- [ ] **Step 1: Полный прогон тестов и анализа**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && flutter pub get && dart analyze && flutter test
```
Expected: `dart analyze` → `No issues found!`; `flutter test` → все тесты PASS (возможны строки-предупреждения google_fonts о сети — не ошибки).

- [ ] **Step 2: Проверить формат и git-состояние**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app/app && dart format --output=none --set-exit-if-changed lib test
cd /Users/pablo/work/receipt-scan-app && git status --short
```
Expected: формат — без изменений (exit 0); рабочее дерево чистое (всё закоммичено).

- [ ] **Step 3: Проверить каталог и доки**

Run:
```bash
cd /Users/pablo/work/receipt-scan-app
ls app/lib/core/theme/ app/lib/shared/components/ docs/conventions/design-system.md
grep -c "export" app/lib/shared/components/components.dart
```
Expected: 4 файла темы; 13 файлов компонентов (12 + barrel); `design-system.md` существует; barrel содержит 12 export-строк.

- [ ] **Step 4: Завершение ветки**

Использовать навык `superpowers:finishing-a-development-branch` для слияния `feat/design-system`
(тесты зелёные — предусловие выполнено).

---

## Self-Review (выполнено при составлении плана)

**1. Покрытие спека:**
- §2 Фундамент/токены → Tasks 2 (AppColors), 3 (AppTokens+context.tokens), 4 (AppTypography), 5 (AppTheme + app.dart).
- §3 Каталог компонентов → Tasks 6–11 (все 12 компонентов + barrel).
- §4 Правила → Task 12 (design-system.md) + Task 13 (CLAUDE.md/скилл).
- §5 Документация и соблюдение → Task 12 (доки), 13 (CLAUDE/скилл), 14 (хук), 15 (субагент).
- §6 Зависимости → Task 1 (google_fonts; intl уже есть).
- §7 Границы → реальные экраны фич не верстаются; только токены+каталог+правила.

**2. Плейсхолдеры:** отсутствуют — в каждом шаге полный код/команды.

**3. Согласованность типов/имён:** `AppTokens` (поля `spaceXs..spaceXxl`, `radiusSm..radiusPill`,
`priceUp/priceDown/success/warning`), `context.tokens`, `AppButtonVariant`, `AppBadgeTone`,
`PriceDirection`, `MoneyText.format(...)`, `PriceDeltaText.directionOf(...)`, barrel
`components.dart` — имена согласованы между задачами, тестами и документом. Импорты —
`package:ticket_app/...`. Команды — из `app/`.
