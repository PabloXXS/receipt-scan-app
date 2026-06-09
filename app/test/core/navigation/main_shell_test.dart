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
                  path: '/b',
                  builder: (c, s) => const Text('Ветка-Статистика')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/c', builder: (c, s) => const Text('Ветка-Скан')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(
                  path: '/d', builder: (c, s) => const Text('Ветка-Профиль')),
            ]),
          ],
        ),
      ],
    );

void main() {
  testWidgets('MainShell: 4 пункта меню, тап переключает ветку',
      (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Чеки', 'Статистика', 'Скан', 'Профиль']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Ветка-Чеки'), findsOneWidget);

    await tester.tap(find.text('Статистика'));
    await tester.pumpAndSettle();
    expect(find.text('Ветка-Статистика'), findsOneWidget);
  });
}
