/// Назначение: тема приложения (ThemeData, цвета, типографика).
///
/// Слой: core/theme
/// Зависимости: flutter material.
/// Ключевые типы: AppTheme.
library;

import 'package:flutter/material.dart';

/// Фабрики тем приложения.
class AppTheme {
  const AppTheme._();

  /// Светлая тема по умолчанию.
  static ThemeData light() => ThemeData(useMaterial3: true);
}
