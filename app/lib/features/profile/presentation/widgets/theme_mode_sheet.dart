/// Назначение: bottom-sheet выбора темы оформления; возвращает ThemeMode или null.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart,
///   shared/components/components.dart.
/// Ключевые типы: showThemeModePicker.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';

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
    isScrollControlled: true,
    builder: (context) {
      final tokens = context.tokens;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: tokens.spaceMd,
            horizontal: tokens.spaceMd,
          ),
          child: RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (v) => Navigator.of(context).pop(v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in _kThemeLabels.entries)
                  AppListTile(
                    title: entry.value,
                    leading: Radio<ThemeMode>(value: entry.key),
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
