/// Назначение: выбор страны при регистрации (country_code → провайдер фиска).
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: flutter material, core/theme/app_tokens.dart,
///   core/constants/supported_countries.dart.
/// Ключевые типы: CountryField.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/supported_countries.dart';
import '../../../../core/theme/app_tokens.dart';

/// Выпадающий список выбора страны.
class CountryField extends StatelessWidget {
  const CountryField({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Страна',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
      items: [
        for (final entry in kSupportedCountries.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
    );
  }
}
