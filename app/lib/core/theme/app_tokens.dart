/// Назначение: дизайн-токены приложения (spacing, radii, durations, семантические цвета)
/// как ThemeExtension, прикрепляемый к ThemeData.
///
/// Слой: core/theme
/// Зависимости: flutter material, dart:ui (lerpDouble), core/theme/app_colors.dart.
/// Ключевые типы: AppTokens, AppTokensX (context.tokens).
library;

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Иммутабельный набор дизайн-токенов, доступный через `Theme.of(context)`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.spaceXxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
    required this.durationFast,
    required this.durationNormal,
    required this.success,
    required this.warning,
    required this.priceUp,
    required this.priceDown,
  });

  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double spaceXxl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusPill;

  final Duration durationFast;
  final Duration durationNormal;

  final Color success;
  final Color warning;
  final Color priceUp;
  final Color priceDown;

  /// Токены светлой темы.
  static const AppTokens light = AppTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusPill: 999,
    durationFast: Duration(milliseconds: 150),
    durationNormal: Duration(milliseconds: 250),
    success: AppColors.successLight,
    warning: AppColors.warningLight,
    priceUp: AppColors.priceUpLight,
    priceDown: AppColors.priceDownLight,
  );

  /// Токены тёмной темы (размеры те же, цвета — тёмные варианты).
  static const AppTokens dark = AppTokens(
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 16,
    spaceXl: 24,
    spaceXxl: 32,
    radiusSm: 8,
    radiusMd: 12,
    radiusLg: 16,
    radiusPill: 999,
    durationFast: Duration(milliseconds: 150),
    durationNormal: Duration(milliseconds: 250),
    success: AppColors.successDark,
    warning: AppColors.warningDark,
    priceUp: AppColors.priceUpDark,
    priceDown: AppColors.priceDownDark,
  );

  @override
  AppTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
    Duration? durationFast,
    Duration? durationNormal,
    Color? success,
    Color? warning,
    Color? priceUp,
    Color? priceDown,
  }) {
    return AppTokens(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
      durationFast: durationFast ?? this.durationFast,
      durationNormal: durationNormal ?? this.durationNormal,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      priceUp: priceUp ?? this.priceUp,
      priceDown: priceDown ?? this.priceDown,
    );
  }

  @override
  AppTokens lerp(covariant ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
      spaceXxl: lerpDouble(spaceXxl, other.spaceXxl, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t)!,
      durationFast: t < 0.5 ? durationFast : other.durationFast,
      durationNormal: t < 0.5 ? durationNormal : other.durationNormal,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      priceUp: Color.lerp(priceUp, other.priceUp, t)!,
      priceDown: Color.lerp(priceDown, other.priceDown, t)!,
    );
  }
}

/// Удобный доступ к токенам: `context.tokens.spaceMd`.
extension AppTokensX on BuildContext {
  /// Дизайн-токены текущей темы.
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
