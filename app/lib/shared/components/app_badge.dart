/// Назначение: бейдж-статус дизайн-системы (статусы чека и т.п.).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppBadge, AppBadgeTone.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Тональность бейджа.
enum AppBadgeTone { neutral, success, warning, error }

/// Небольшой цветной бейдж с подписью.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.neutral,
    super.key,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final bg = switch (tone) {
      AppBadgeTone.neutral => scheme.surfaceContainerHighest,
      AppBadgeTone.success => tokens.success,
      AppBadgeTone.warning => tokens.warning,
      AppBadgeTone.error => scheme.errorContainer,
    };
    final fg = switch (tone) {
      AppBadgeTone.neutral => scheme.onSurfaceVariant,
      AppBadgeTone.error => scheme.onErrorContainer,
      _ => Colors.white,
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}
