# Навигационная оболочка + нижнее меню — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Добавить навигационную оболочку приложения после входа — нижнее меню (Material 3 `NavigationBar`) с 4 разделами (Чеки · Статистика · Скан · Профиль), экранами-заглушками и выходом из аккаунта на Профиле.

**Architecture:** `GoRouter StatefulShellRoute.indexedStack` с 4 ветками; оболочка `MainShell` (`core/navigation/`) рендерит `navigationShell` в `Scaffold` с `NavigationBar`. Auth-маршруты остаются вне оболочки; `redirect` уводит авторизованного на `/receipts`. Экраны-заглушки — feature-first, на каталоге `shared/components`.

**Tech Stack:** Flutter, go_router 14.2 (`StatefulShellRoute`), Riverpod, Material 3. Пакет `ticket_app`. Команды — из `app/`.

**Источник истины:** [docs/superpowers/specs/2026-06-09-app-shell-nav-design.md](../specs/2026-06-09-app-shell-nav-design.md).

**Замечание по среде:** iOS-сборка работает с временно отключённым `mobile_scanner` (см. память `ios-simulator-run`). Этот план логику скана не реализует — только заглушку, импортов `mobile_scanner` не добавляет.

---

## Карта файлов

**Создаём:**
- `app/lib/core/navigation/main_shell.dart` — оболочка с `NavigationBar`
- `app/lib/features/receipts/presentation/screens/receipts_screen.dart`
- `app/lib/features/statistics/presentation/screens/statistics_screen.dart`
- `app/lib/features/scan/presentation/screens/scan_screen.dart`
- `app/lib/features/profile/presentation/screens/profile_screen.dart`
- Тесты: `test/core/navigation/main_shell_test.dart`,
  `test/features/{receipts,statistics,scan,profile}/presentation/screens/*_test.dart`

**Модифицируем:**
- `app/lib/core/router/app_routes.dart` — константы вкладок
- `app/lib/core/router/auth_redirect.dart` — цель авторизованного → `receipts`
- `app/test/core/router/auth_redirect_test.dart` — обновлённые кейсы
- `app/lib/core/router/app_router.dart` — `StatefulShellRoute` + ветки
- `docs/architecture/overview.md` — схема навигации

---

## Task 1: Маршруты вкладок + обновление redirect (TDD)

**Files:**
- Modify: `app/lib/core/router/app_routes.dart`
- Modify: `app/lib/core/router/auth_redirect.dart`
- Modify: `app/test/core/router/auth_redirect_test.dart`

- [ ] **Step 1: Добавить константы вкладок в `app_routes.dart`**

Замени класс `AppRoutes` целиком на:
```dart
/// Пути маршрутов приложения.
abstract final class AppRoutes {
  static const String home = '/';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String checkEmail = '/check-email';
  static const String resetPassword = '/reset-password';

  // Вкладки нижнего меню.
  static const String receipts = '/receipts';
  static const String statistics = '/statistics';
  static const String scan = '/scan';
  static const String profile = '/profile';
}
```

- [ ] **Step 2: Обновить тест redirect (он станет падать)**

Замени содержимое `app/test/core/router/auth_redirect_test.dart` на:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/router/app_routes.dart';
import 'package:ticket_app/core/router/auth_redirect.dart';

void main() {
  group('authRedirect', () {
    test('неавторизованный на приватном маршруте → на вход', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.receipts),
        AppRoutes.signIn,
      );
    });

    test('неавторизованный на home → на вход', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.home),
        AppRoutes.signIn,
      );
    });

    test('неавторизованный на публичном маршруте → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: false, location: AppRoutes.signUp),
        isNull,
      );
    });

    test('авторизованный на экране входа → на чеки', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.signIn),
        AppRoutes.receipts,
      );
    });

    test('авторизованный на home → на чеки', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.home),
        AppRoutes.receipts,
      );
    });

    test('авторизованный на вкладке → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.statistics),
        isNull,
      );
    });

    test('авторизованный (recovery) на reset-password → без редиректа', () {
      expect(
        authRedirect(isAuthenticated: true, location: AppRoutes.resetPassword),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 3: Запустить тест — убедиться, что падает**

Run: `cd app && flutter test test/core/router/auth_redirect_test.dart`
Expected: FAIL (кейс «на чеки» возвращает `/`, а не `/receipts`).

- [ ] **Step 4: Обновить `auth_redirect.dart`**

Замени тело функции `authRedirect` (док-комментарий и сигнатуру оставь). Итоговый файл ниже целиком:
```dart
/// Назначение: чистая политика перенаправления по состоянию авторизации.
///
/// Слой: core/router
/// Зависимости: core/router/app_routes.dart.
/// Ключевые типы: authRedirect.
library;

import 'app_routes.dart';

const Set<String> _publicRoutes = {
  AppRoutes.signIn,
  AppRoutes.signUp,
  AppRoutes.forgotPassword,
  AppRoutes.checkEmail,
};

/// Возвращает путь для перенаправления или `null`, если редирект не нужен.
///
/// Правила: неавторизованный пускается только на публичные auth-маршруты;
/// авторизованный с публичного auth-маршрута или `home` уводится на первую
/// вкладку (`receipts`), кроме `resetPassword` (доступен по recovery-сессии).
String? authRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  final onPublic = _publicRoutes.contains(location);
  final onReset = location == AppRoutes.resetPassword;

  if (!isAuthenticated) {
    return onPublic ? null : AppRoutes.signIn;
  }
  if (onReset) return null;
  if (onPublic || location == AppRoutes.home) return AppRoutes.receipts;
  return null;
}
```

- [ ] **Step 5: Запустить тест — убедиться, что проходит**

Run: `cd app && flutter test test/core/router/auth_redirect_test.dart`
Expected: PASS (7 тестов).

- [ ] **Step 6: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/router/app_routes.dart app/lib/core/router/auth_redirect.dart app/test/core/router/auth_redirect_test.dart
git commit -m "feat(nav): маршруты вкладок + redirect авторизованного на receipts"
```

---

## Task 2: Экраны-заглушки Чеки / Статистика / Скан (TDD)

**Files:**
- Create: `app/lib/features/receipts/presentation/screens/receipts_screen.dart`
- Create: `app/lib/features/statistics/presentation/screens/statistics_screen.dart`
- Create: `app/lib/features/scan/presentation/screens/scan_screen.dart`
- Test: `app/test/features/receipts/presentation/screens/receipts_screen_test.dart`
- Test: `app/test/features/statistics/presentation/screens/statistics_screen_test.dart`
- Test: `app/test/features/scan/presentation/screens/scan_screen_test.dart`

Контекст: `AppScaffold(title:, body:)` и `AppEmptyState(message:, icon:)` — из `shared/components` (`components.dart`), оба `const`-конструируемы. Хелпер `pumpApp` уже есть в `test/helpers/pump_app.dart`.

- [ ] **Step 1: Написать падающие render-тесты**

`app/test/features/receipts/presentation/screens/receipts_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ReceiptsScreen рендерит заголовок и пусто-состояние', (tester) async {
    await pumpApp(tester, const ReceiptsScreen());
    expect(find.text('Чеки'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
```

`app/test/features/statistics/presentation/screens/statistics_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('StatisticsScreen рендерит заголовок и пусто-состояние', (tester) async {
    await pumpApp(tester, const StatisticsScreen());
    expect(find.text('Статистика'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
```

`app/test/features/scan/presentation/screens/scan_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';
import 'package:ticket_app/shared/components/app_empty_state.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('ScanScreen рендерит заголовок и пусто-состояние', (tester) async {
    await pumpApp(tester, const ScanScreen());
    expect(find.text('Сканировать'), findsOneWidget);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
```

Run: `cd app && flutter test test/features/receipts test/features/statistics test/features/scan`
Expected: FAIL (экраны не существуют).

- [ ] **Step 2: Создать `receipts_screen.dart`**

```dart
/// Назначение: экран-заглушка раздела «Чеки» (список чеков — в фиче receipts позже).
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: shared/components.
/// Ключевые типы: ReceiptsScreen.
library;

import 'package:flutter/material.dart';

import '../../../../shared/components/components.dart';

/// Экран-заглушка списка чеков.
class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Чеки',
      body: AppEmptyState(
        message: 'Здесь появятся ваши чеки.\nОтсканируйте первый на вкладке «Скан».',
        icon: Icons.receipt_long_outlined,
      ),
    );
  }
}
```

- [ ] **Step 3: Создать `statistics_screen.dart`**

```dart
/// Назначение: экран-заглушка раздела «Статистика» (графики/бюджеты — позже).
///
/// Слой: presentation
/// Фича: statistics
/// Зависимости: shared/components.
/// Ключевые типы: StatisticsScreen.
library;

import 'package:flutter/material.dart';

import '../../../../shared/components/components.dart';

/// Экран-заглушка статистики трат.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Статистика',
      body: AppEmptyState(
        message: 'Статистика трат появится после первых чеков.',
        icon: Icons.bar_chart_outlined,
      ),
    );
  }
}
```

- [ ] **Step 4: Создать `scan_screen.dart`**

```dart
/// Назначение: экран-заглушка раздела «Скан» (сканирование чека — в фиче scan позже).
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: shared/components.
/// Ключевые типы: ScanScreen.
library;

import 'package:flutter/material.dart';

import '../../../../shared/components/components.dart';

/// Экран-заглушка сканирования чека.
class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Сканировать',
      body: AppEmptyState(
        message: 'Сканирование QR и фото чека появится здесь.',
        icon: Icons.qr_code_scanner,
      ),
    );
  }
}
```

- [ ] **Step 5: Запустить тесты — убедиться, что проходят**

Run: `cd app && flutter test test/features/receipts test/features/statistics test/features/scan`
Expected: PASS (3 теста).

- [ ] **Step 6: Анализ + commit**

```bash
cd /Users/pablo/work/receipt-scan-app/app && dart analyze lib/features/receipts/presentation lib/features/statistics/presentation lib/features/scan/presentation
cd /Users/pablo/work/receipt-scan-app
git add app/lib/features/receipts/presentation/screens app/lib/features/statistics/presentation/screens app/lib/features/scan/presentation/screens app/test/features/receipts app/test/features/statistics app/test/features/scan
git commit -m "feat(nav): экраны-заглушки Чеки/Статистика/Скан"
```

---

## Task 3: Экран Профиль + выход из аккаунта (TDD)

**Files:**
- Create: `app/lib/features/profile/presentation/screens/profile_screen.dart`
- Test: `app/test/features/profile/presentation/screens/profile_screen_test.dart`

Контекст: `authControllerProvider` (`features/auth/presentation/controllers/auth_controller.dart`) — `AsyncNotifier`; `ref.read(authControllerProvider.notifier).signOut()` вызывает выход. `authRepositoryProvider` (`features/auth/data/repositories/auth_repository_impl.dart`) — для override в тесте. `FakeAuthRepository` (`test/features/auth/auth_test_fakes.dart`) пишет вызовы в `calls`. `AppButton(label:, onPressed:, variant:, expanded:, loading:)` с `AppButtonVariant.destructive`.

- [ ] **Step 1: Написать падающий тест**

`app/test/features/profile/presentation/screens/profile_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:ticket_app/shared/components/app_button.dart';

import '../../../../helpers/pump_app.dart';
import '../../../auth/auth_test_fakes.dart';

void main() {
  testWidgets('ProfileScreen: заголовок и кнопка «Выйти»', (tester) async {
    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
    );
    expect(find.text('Профиль'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Выйти'), findsOneWidget);
  });

  testWidgets('ProfileScreen: тап «Выйти» вызывает signOut', (tester) async {
    final repo = FakeAuthRepository();
    await pumpApp(
      tester,
      const ProfileScreen(),
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.widgetWithText(AppButton, 'Выйти'));
    await tester.pump();
    expect(repo.calls, contains('signOut'));
  });
}
```

Run: `cd app && flutter test test/features/profile/presentation/screens/profile_screen_test.dart`
Expected: FAIL (экран не существует).

- [ ] **Step 2: Создать `profile_screen.dart`**

```dart
/// Назначение: экран-заглушка раздела «Профиль» + выход из аккаунта.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: auth/presentation/controllers/auth_controller.dart, shared/components,
///   core/theme/app_tokens.dart.
/// Ключевые типы: ProfileScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Экран-заглушка профиля с кнопкой выхода.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AppScaffold(
      title: 'Профиль',
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          children: [
            const Expanded(
              child: AppEmptyState(
                message: 'Профиль и настройки появятся здесь.',
                icon: Icons.person_outline,
              ),
            ),
            AppButton(
              label: 'Выйти',
              variant: AppButtonVariant.destructive,
              expanded: true,
              loading: isLoading,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Запустить тест — убедиться, что проходит**

Run: `cd app && flutter test test/features/profile/presentation/screens/profile_screen_test.dart`
Expected: PASS (2 теста).

- [ ] **Step 4: Анализ + commit**

```bash
cd /Users/pablo/work/receipt-scan-app/app && dart analyze lib/features/profile/presentation
cd /Users/pablo/work/receipt-scan-app
git add app/lib/features/profile/presentation/screens app/test/features/profile/presentation/screens
git commit -m "feat(nav): экран Профиль с выходом из аккаунта"
```

---

## Task 4: Оболочка `MainShell` с нижним меню (TDD)

**Files:**
- Create: `app/lib/core/navigation/main_shell.dart`
- Test: `app/test/core/navigation/main_shell_test.dart`

Контекст: go_router 14.2 `StatefulNavigationShell` имеет `.currentIndex` и `.goBranch(index, {initialLocation})`. `NavigationBar` — Material 3, навигационный chrome (разрешён конвенциями). Тест строит свой минимальный `GoRouter` с `StatefulShellRoute`, т.к. `StatefulNavigationShell` нельзя создать вне роутера.

- [ ] **Step 1: Написать падающий тест**

`app/test/core/navigation/main_shell_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ticket_app/core/navigation/main_shell.dart';

GoRouter _router() => GoRouter(
      initialLocation: '/a',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/a', builder: (c, s) => const Text('Ветка-Чеки')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/b', builder: (c, s) => const Text('Ветка-Статистика')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/c', builder: (c, s) => const Text('Ветка-Скан')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/d', builder: (c, s) => const Text('Ветка-Профиль')),
            ]),
          ],
        ),
      ],
    );

void main() {
  testWidgets('MainShell: 4 пункта меню, тап переключает ветку', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Чеки', 'Статистика', 'Скан', 'Профиль']) {
      expect(find.text(label), findsOneWidget);
    }
    // начальная ветка
    expect(find.text('Ветка-Чеки'), findsOneWidget);

    // переключение на «Статистика»
    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.text('Ветка-Статистика'), findsOneWidget);
  });
}
```

Run: `cd app && flutter test test/core/navigation/main_shell_test.dart`
Expected: FAIL (`main_shell.dart` не существует).

- [ ] **Step 2: Создать `main_shell.dart`**

```dart
/// Назначение: навигационная оболочка с нижним меню (Material 3 NavigationBar).
///
/// Слой: core/navigation
/// Зависимости: flutter material, go_router (StatefulNavigationShell).
/// Ключевые типы: MainShell.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Каркас авторизованной зоны: тело активной ветки + нижнее меню из 4 вкладок.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  /// Управляет ветками вкладок (предоставляется StatefulShellRoute).
  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // Повторный тап по активной вкладке возвращает её к корню.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Чеки',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Скан',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Запустить тест — убедиться, что проходит**

Run: `cd app && flutter test test/core/navigation/main_shell_test.dart`
Expected: PASS.

- [ ] **Step 4: Анализ + commit**

```bash
cd /Users/pablo/work/receipt-scan-app/app && dart analyze lib/core/navigation/main_shell.dart test/core/navigation/main_shell_test.dart
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/navigation/main_shell.dart app/test/core/navigation/main_shell_test.dart
git commit -m "feat(nav): MainShell с нижним меню (NavigationBar, 4 вкладки)"
```

---

## Task 5: Проводка роутера (StatefulShellRoute)

**Files:**
- Modify: `app/lib/core/router/app_router.dart`

Контекст: текущий роутер имеет плоские auth-маршруты + `GoRoute(home → _HomePlaceholder)`. Заменяем: убираем `_HomePlaceholder` и его `GoRoute`, добавляем `StatefulShellRoute.indexedStack` с 4 ветками, `initialLocation` → `receipts`.

- [ ] **Step 1: Заменить `app_router.dart` целиком**

```dart
/// Назначение: конфигурация навигации (GoRouter) с redirect и нижним меню.
///
/// Слой: core/router
/// Зависимости: go_router, flutter_riverpod, core/auth, core/navigation,
///   core/supabase, экраны фич auth/receipts/statistics/scan/profile.
/// Ключевые типы: appRouterProvider.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/check_email_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/sign_in_screen.dart';
import '../../features/auth/presentation/screens/sign_up_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/receipts/presentation/screens/receipts_screen.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/statistics/presentation/screens/statistics_screen.dart';
import '../auth/auth_providers.dart';
import '../navigation/main_shell.dart';
import '../supabase/supabase_providers.dart';
import 'app_routes.dart';
import 'auth_redirect.dart';

/// Провайдер корневого роутера приложения.
final appRouterProvider = Provider<GoRouter>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final refreshStream = GoRouterRefreshStream(client.auth.onAuthStateChange);
  ref.onDispose(refreshStream.dispose);
  return GoRouter(
    initialLocation: AppRoutes.receipts,
    refreshListenable: refreshStream,
    redirect: (context, state) => authRedirect(
      isAuthenticated: client.auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkEmail,
        builder: (context, state) => const CheckEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.receipts,
                builder: (context, state) => const ReceiptsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scan,
                builder: (context, state) => const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

- [ ] **Step 2: Анализ**

Run: `cd app && dart analyze lib/core/router/app_router.dart`
Expected: No issues found.

- [ ] **Step 3: Полный прогон тестов**

Run: `cd app && flutter test`
Expected: все тесты PASS.

- [ ] **Step 4: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/core/router/app_router.dart
git commit -m "feat(nav): StatefulShellRoute с нижним меню, initialLocation=receipts"
```

---

## Task 6: Верификация и документация

**Files:**
- Modify: `docs/architecture/overview.md`

- [ ] **Step 1: Полная верификация**

Run: `cd app && dart analyze && flutter test && dart format --set-exit-if-changed lib test`
Expected: `No issues found.`, все тесты PASS, формат без изменений (иначе закоммить формат).

- [ ] **Step 2: Ревью дизайн-системы субагентом**

Запусти `flutter-design-reviewer` на `app/lib/features/{receipts,statistics,scan,profile}/presentation/` и `app/lib/core/navigation/main_shell.dart`.
Ожидаемо: экраны на каталоге; `NavigationBar` — допустимый навигационный chrome. Исправь замечания.

- [ ] **Step 3: Обновить `docs/architecture/overview.md`**

Добавь в подходящий раздел (или новый «## Навигация») абзац:
```markdown
## Навигация

После входа — нижнее меню (Material 3 `NavigationBar`) с 4 разделами: Чеки, Статистика,
Скан, Профиль. Реализовано через `GoRouter StatefulShellRoute.indexedStack`
(оболочка `lib/core/navigation/main_shell.dart`); каждая вкладка — отдельная ветка со
своим стеком. Auth-экраны — вне оболочки; `redirect` уводит авторизованного на `/receipts`.
Выход из аккаунта — на вкладке Профиль.
```

- [ ] **Step 4: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add docs/architecture/overview.md app/lib app/test
git commit -m "docs(nav): схема навигации в overview; финальная верификация"
```

---

## Самопроверка плана (выполнена при написании)

- **Покрытие спека:** 4 вкладки — Task 2/3 (экраны) + Task 4 (MainShell) + Task 5 (ветки);
  StatefulShellRoute — Task 4/5; redirect home→receipts — Task 1; выход на Профиле — Task 3;
  экраны на каталоге — Task 2/3 + design-reviewer (Task 6); тесты redirect/MainShell/экранов —
  Task 1/2/3/4; overview.md — Task 6.
- **Плейсхолдеры:** не обнаружено — весь код задач готов к копированию.
- **Согласованность типов:** `AppRoutes.{receipts,statistics,scan,profile}` едины во всех
  задачах; `MainShell(navigationShell:)`, `authRedirect(isAuthenticated:, location:)`,
  `AppScaffold(title:, body:)`, `AppEmptyState(message:, icon:)`, `AppButton(label:, variant:,
  expanded:, loading:, onPressed:)`, `authControllerProvider`/`authRepositoryProvider`/
  `FakeAuthRepository.calls` — согласованы со существующим кодом auth-фичи.
```
