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

  /// Базовый цвет бренда (royal blue) — из него строится палитра M3.
  static const Color seed = Color(0xFF2563EB);

  // --- light ---
  static const Color successLight = Color(0xFF2E7D32);
  static const Color warningLight = Color(0xFFB26A00);

  /// Текст на фоне [successLight] (тёмно-зелёный) — белый (контраст ~5.1, AA).
  static const Color onSuccessLight = Color(0xFFFFFFFF);

  /// Текст на фоне [warningLight] (тёмно-янтарный) — чёрный (контраст ~5.0, AA;
  /// белый дал бы лишь ~4.2).
  static const Color onWarningLight = Color(0xFF000000);

  /// Цена выросла — «дороже» (красный).
  static const Color priceUpLight = Color(0xFFC62828);

  /// Цена снизилась — «выгоднее» (зелёный).
  static const Color priceDownLight = Color(0xFF2E7D32);

  // --- dark ---
  static const Color successDark = Color(0xFF81C784);
  static const Color warningDark = Color(0xFFFFB74D);

  /// Текст на фоне [successDark] (светло-зелёный) — чёрный (контраст ~11, AA).
  static const Color onSuccessDark = Color(0xFF000000);

  /// Текст на фоне [warningDark] (светло-янтарный) — чёрный (контраст ~12, AA).
  static const Color onWarningDark = Color(0xFF000000);
  static const Color priceUpDark = Color(0xFFEF9A9A);
  static const Color priceDownDark = Color(0xFFA5D6A7);
}
