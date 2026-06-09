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
