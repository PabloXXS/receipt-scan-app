/// Назначение: bottom-sheet выбора страны; возвращает выбранный код или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/constants/supported_countries.dart,
///   core/theme/app_tokens.dart, shared/components/components.dart.
/// Ключевые типы: showCountryPicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/supported_countries.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';

/// Показывает список стран. Возвращает код выбранной страны или null (отмена).
Future<String?> showCountryPicker(
  BuildContext context, {
  required String current,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spaceMd,
            horizontal: tokens.spaceMd,
          ),
          child: RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in kSupportedCountries.entries)
                  AppListTile(
                    title: entry.value,
                    leading: Radio<String>(value: entry.key),
                    onTap: () => Navigator.of(context).pop(entry.key),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
