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
        message:
            'Здесь появятся ваши чеки.\nОтсканируйте первый на вкладке «Скан».',
        icon: Icons.receipt_long_outlined,
      ),
    );
  }
}
