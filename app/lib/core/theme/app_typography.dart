/// Назначение: типографика дизайн-системы — шрифт Inter поверх M3 TextTheme.
///
/// Слой: core/theme
/// Зависимости: flutter material, google_fonts.
/// Ключевые типы: AppTypography.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Фабрика TextTheme приложения.
class AppTypography {
  const AppTypography._();

  /// Применяет шрифт Inter к [base] (типографической шкале M3).
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.interTextTheme(base);
}
