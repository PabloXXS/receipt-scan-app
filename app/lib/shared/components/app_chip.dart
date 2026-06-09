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
