import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
        final double height = math.max(pulledExtent, refreshIndicatorExtent);
        final double progress = (pulledExtent / refreshTriggerPullDistance)
            .clamp(0.0, 1.0);
        final bool spinning = mode == RefreshIndicatorMode.refresh ||
            mode == RefreshIndicatorMode.done;
        final Widget child = spinning
            ? const CupertinoActivityIndicator(color: Colors.white)
            : _ProgressRing(value: progress);
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        value: value == 1.0 ? null : value,
        strokeWidth: 2.5,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        backgroundColor: Colors.white24,
      ),
    );
  }
}


