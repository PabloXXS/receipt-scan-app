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
