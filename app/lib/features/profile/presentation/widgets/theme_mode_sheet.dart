/// Назначение: bottom-sheet выбора темы оформления; возвращает ThemeMode или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: showThemeModePicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

const Map<ThemeMode, String> _kThemeLabels = {
  ThemeMode.system: 'Системная',
  ThemeMode.light: 'Светлая',
  ThemeMode.dark: 'Тёмная',
};

/// Показывает выбор темы. Возвращает выбранный [ThemeMode] или null (отмена).
Future<ThemeMode?> showThemeModePicker(
  BuildContext context, {
  required ThemeMode current,
}) {
  return showModalBottomSheet<ThemeMode>(
    context: context,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in _kThemeLabels.entries)
                  RadioListTile<ThemeMode>(
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
