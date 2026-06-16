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
