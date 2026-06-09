/// Назначение: карточка-контейнер дизайн-системы (единый радиус/отступы из токенов).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppCard.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Карточка с единым скруглением и внутренним отступом; опционально кликабельна.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(tokens.radiusLg);
    final content = Padding(
      padding: padding ?? EdgeInsets.all(tokens.spaceLg),
      child: child,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}
