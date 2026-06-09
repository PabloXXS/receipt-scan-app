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
