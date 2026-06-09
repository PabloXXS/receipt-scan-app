/// Назначение: пустое состояние дизайн-системы (нет данных).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppEmptyState.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Заглушка «нет данных» с иконкой и сообщением.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: scheme.onSurfaceVariant),
            SizedBox(height: tokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
