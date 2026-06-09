/// Назначение: отображение изменения цены со стрелкой и цветом (доменный компонент).
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart, shared/components/money_text.dart.
/// Ключевые типы: PriceDeltaText, PriceDirection.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import 'money_text.dart';

/// Направление изменения цены.
enum PriceDirection { up, down, flat }

/// Текст изменения цены: стрелка + абсолютная величина, окрашенные по направлению.
class PriceDeltaText extends StatelessWidget {
  const PriceDeltaText({
    required this.delta,
    required this.currencyCode,
    this.locale,
    super.key,
  });

  /// Изменение цены (текущая − эталонная).
  final num delta;

  /// Код валюты.
  final String currencyCode;

  /// Локаль; по умолчанию — локаль контекста.
  final String? locale;

  /// Направление по знаку дельты (чистая функция).
  static PriceDirection directionOf(num delta) {
    if (delta > 0) return PriceDirection.up;
    if (delta < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final direction = directionOf(delta);
    final color = switch (direction) {
      PriceDirection.up => tokens.priceUp,
      PriceDirection.down => tokens.priceDown,
      PriceDirection.flat => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    final icon = switch (direction) {
      PriceDirection.up => Icons.arrow_upward,
      PriceDirection.down => Icons.arrow_downward,
      PriceDirection.flat => Icons.remove,
    };
    final loc = locale ?? Localizations.localeOf(context).toString();
    final style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: tokens.spaceXs),
        Text(
          MoneyText.format(delta.abs(),
              currencyCode: currencyCode, locale: loc),
          style: style,
        ),
      ],
    );
  }
}
