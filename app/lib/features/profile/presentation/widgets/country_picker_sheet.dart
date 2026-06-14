/// Назначение: bottom-sheet выбора страны; возвращает выбранный код или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/constants/supported_countries.dart,
///   core/theme/app_tokens.dart.
/// Ключевые типы: showCountryPicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/supported_countries.dart';
import '../../../../core/theme/app_tokens.dart';

/// Показывает список стран. Возвращает код выбранной страны или null (отмена).
Future<String?> showCountryPicker(
  BuildContext context, {
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in kSupportedCountries.entries)
                  RadioListTile<String>(
                    value: entry.key,
                    title: Text(entry.value),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
