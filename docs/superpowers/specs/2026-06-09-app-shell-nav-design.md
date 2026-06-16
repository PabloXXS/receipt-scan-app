# Дизайн: навигационная оболочка + нижнее меню (app shell) — v1

Дата: 2026-06-09
Статус: утверждён, готов к написанию плана.

## Назначение

Базовая навигационная оболочка приложения после входа: нижнее меню (bottom navigation)
с 4 разделами и экранами-заглушками. Даёт каркас, в который последующие фичи добавляют
реальную логику.

## Утверждённые решения

1. **Состав вкладок (4):** Чеки (`receipts`) · Статистика (`statistics`) · Скан (`scan`) ·
   Профиль (`profile`). Цены, карты лояльности, семья — вне этой итерации.
2. **Подход:** `GoRouter StatefulShellRoute.indexedStack` — каждая вкладка как ветка со
   своим стеком и сохранением состояния, каждая deep-link-абельна. Отклонён вариант
   «один экран + IndexedStack + Riverpod-индекс» (вкладки не маршруты, ручной back).
3. **Размещение оболочки:** `lib/core/navigation/main_shell.dart` (навигационный chrome
   уровня приложения, рядом с `core/router`).
4. **Выход из аккаунта** добавляется на экран Профиль (использует существующий
   `AuthController.signOut()`); закрывает ранее отмеченный dead-code.

## Архитектура

- В `core/router/app_router.dart` добавляется `StatefulShellRoute.indexedStack` с 4
  ветками (`/receipts`, `/statistics`, `/scan`, `/profile`). Auth-маршруты
  (`/sign-in`, `/sign-up`, `/forgot-password`, `/check-email`, `/reset-password`)
  остаются вне оболочки.
- `MainShell` (`lib/core/navigation/main_shell.dart`) — `Scaffold` с Material 3
  `NavigationBar` внизу; в `body` — `navigationShell` (тело активной ветки). Переключение
  вкладок — `navigationShell.goBranch(index)`. `NavigationBar` — навигационный chrome
  (стоковый Material разрешён конвенциями для разметки/навигации; это не запрещённый
  UI-примитив каталога).
- `redirect` (`core/router/auth_redirect.dart`): авторизованный на публичном auth-маршруте
  → `/receipts` (вместо `home`); неавторизованный вне публичных → `/sign-in`;
  `/reset-password` при recovery-сессии — без редиректа (как сейчас). `home ('/')`
  редиректит на `/receipts`.

## Экраны-заглушки (feature-first)

Каждый — `AppScaffold(title:)` + `AppEmptyState` («Скоро здесь будет …») из каталога
`shared/components`. Русские подписи, иконки Material. Light/dark.

| Файл | Маршрут | Заголовок | Иконка nav |
|---|---|---|---|
| `features/receipts/presentation/screens/receipts_screen.dart` | `/receipts` | Чеки | `Icons.receipt_long` |
| `features/statistics/presentation/screens/statistics_screen.dart` | `/statistics` | Статистика | `Icons.bar_chart` |
| `features/scan/presentation/screens/scan_screen.dart` | `/scan` | Сканировать | `Icons.qr_code_scanner` |
| `features/profile/presentation/screens/profile_screen.dart` | `/profile` | Профиль | `Icons.person` |

**Профиль** дополнительно содержит кнопку **«Выйти»** (`AppButton`, variant `destructive`/
`secondary`), вызывающую `ref.read(authControllerProvider.notifier).signOut()`. После
выхода стрим `onAuthStateChange` эмитит `signedOut` → `redirect` уводит на `/sign-in`.

## Маршруты и константы

`AppRoutes` пополняется: `receipts = '/receipts'`, `statistics = '/statistics'`,
`scan = '/scan'`, `profile = '/profile'`. `home = '/'` сохраняется и редиректит на
`/receipts`. Публичный набор auth-маршрутов в `auth_redirect.dart` не меняется; меняется
лишь цель для авторизованного пользователя (`home` → `receipts`).

## Дизайн-система

Экраны — только на каталоге (`AppScaffold`, `AppEmptyState`, `AppButton`), без сырых
UI-примитивов и хардкода; токены через `context.tokens`. `NavigationBar` — единственный
стоковый Material-навигационный элемент (chrome). Проверка субагентом
`flutter-design-reviewer`.

## Тестирование

- `auth_redirect_test.dart` — обновить кейсы: авторизованный на `/sign-in` → `/receipts`
  (вместо `/`); добавить кейс `home → /receipts`.
- `MainShell` widget-тест: рендерит `NavigationBar` c 4 destinations; тап по вкладке
  вызывает переключение ветки (через тестовый `GoRouter` с `StatefulShellRoute`).
- Render-тесты заглушек: заголовок + `AppEmptyState` присутствуют.
- Профиль: тап «Выйти» вызывает `signOut` на фейковом `AuthRepository` (override
  `authRepositoryProvider`).
- Тесты зеркалят `lib/`; учесть заглушку google_fonts (`flutter_test_config.dart`).

## Границы (YAGNI)

Только оболочка, 4 заглушки и выход. Реальная логика разделов, карты лояльности, семья,
цены — отдельными фичами позже.

## Затрагиваемые документы

- `docs/architecture/overview.md` — зафиксировать схему навигации (bottom nav, 4 раздела).
- Файлы фич (`receipts/statistics/scan/profile`) — обновятся при их реализации.
