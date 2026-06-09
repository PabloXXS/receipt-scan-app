/// Назначение: отображение денежной суммы по валюте/локали (доменный компонент).
///
/// Слой: shared/components
/// Зависимости: flutter material, intl (NumberFormat).
/// Ключевые типы: MoneyText.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Текст с денежной суммой, отформатированной по [currencyCode] и локали.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    required this.currencyCode,
    this.locale,
    this.style,
    super.key,
  });

  /// Сумма.
  final num amount;

  /// Код валюты (ISO 4217), напр. `RUB`, `USD`.
  final String currencyCode;

  /// Локаль форматирования; по умолчанию — локаль контекста.
  final String? locale;

  /// Переопределение стиля; по умолчанию — `textTheme.bodyMedium`.
  final TextStyle? style;

  /// Чистая функция форматирования (тестируется отдельно от виджета).
  static String format(
    num amount, {
    required String currencyCode,
    String? locale,
  }) {
    return NumberFormat.simpleCurrency(locale: locale, name: currencyCode)
        .format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final loc = locale ?? Localizations.localeOf(context).toString();
    return Text(
      format(amount, currencyCode: currencyCode, locale: loc),
      style: style ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
