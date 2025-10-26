import 'package:flutter/cupertino.dart';

/// Cupertino-style pull-to-refresh that shows hint text while pulling
/// and a spinner while refreshing. Designed to sit under a fixed blue header.
class BluePullToRefresh extends StatelessWidget {
  const BluePullToRefresh({
    super.key,
    required this.onRefresh,
    required this.backgroundColor,
    required this.topRadius,
  });

  final Future<void> Function() onRefresh;
  final Color backgroundColor;
  final double topRadius;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        RefreshIndicatorMode mode,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        final double height = refreshIndicatorExtent;
        final Widget child = CupertinoActivityIndicator(
          color: CupertinoColors.label.resolveFrom(context),
        );
        return ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topRadius),
            topRight: Radius.circular(topRadius),
          ),
          child: Container(
            color: backgroundColor,
            height: height,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
    );
  }
}

// Удален неиспользуемый класс _ProgressRing
