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
