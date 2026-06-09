/// Назначение: палитра-источник дизайн-системы — seed и семантические бренд-цвета.
///
/// Слой: core/theme
/// Зависимости: flutter material (Color).
/// Ключевые типы: AppColors.
library;

import 'package:flutter/material.dart';

/// Сырые цветовые константы дизайн-системы.
///
/// `ColorScheme` генерируется из [seed] (см. AppTheme). Семантические цвета,
/// которых нет в `ColorScheme`, заданы парами для светлой/тёмной темы и
/// прокидываются через `AppTokens`.
class AppColors {
  const AppColors._();

  /// Базовый цвет бренда (emerald) — из него строится палитра M3.
  static const Color seed = Color(0xFF2E7D5B);

  // --- light ---
  static const Color successLight = Color(0xFF2E7D32);
  static const Color warningLight = Color(0xFFB26A00);

  /// Цена выросла — «дороже» (красный).
  static const Color priceUpLight = Color(0xFFC62828);

  /// Цена снизилась — «выгоднее» (зелёный).
  static const Color priceDownLight = Color(0xFF2E7D32);

  // --- dark ---
  static const Color successDark = Color(0xFF81C784);
  static const Color warningDark = Color(0xFFFFB74D);
  static const Color priceUpDark = Color(0xFFEF9A9A);
  static const Color priceDownDark = Color(0xFFA5D6A7);
}
