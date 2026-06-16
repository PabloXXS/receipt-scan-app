/// Назначение: примитив скелетон-загрузки — пульсирующий плейсхолдер.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppSkeleton.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Длительность одного такта пульсации скелетона.
const Duration _kSkeletonPeriod = Duration(milliseconds: 1100);

/// Пульсирующий плейсхолдер для скелетон-загрузки.
///
/// [width] null — занимает доступную ширину. Для круга задай [shape] = circle.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    required this.height,
    this.width,
    this.shape = BoxShape.rectangle,
    this.radius,
    super.key,
  });

  final double height;
  final double? width;
  final BoxShape shape;
  final double? radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _kSkeletonPeriod,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = Theme.of(context).colorScheme.onSurface;
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.08, end: 0.20).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius ?? tokens.radiusSm),
          ),
        ),
      ),
    );
  }
}
