/// Назначение: тема приложения — ThemeData для светлого и тёмного режимов на основе
/// seed-цвета (M3), с типографикой Inter и прикреплёнными дизайн-токенами.
///
/// Слой: core/theme
/// Зависимости: flutter material, core/theme/{app_colors,app_tokens,app_typography}.dart.
/// Ключевые типы: AppTheme.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Фабрики тем приложения.
class AppTheme {
  const AppTheme._();

  /// Светлая тема.
  static ThemeData light() => _build(Brightness.light, AppTokens.light);

  /// Тёмная тема.
  static ThemeData dark() => _build(Brightness.dark, AppTokens.dark);

  static ThemeData _build(Brightness brightness, AppTokens tokens) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      extensions: <ThemeExtension<dynamic>>[tokens],
    );
  }
}
