/// Назначение: выбор темы оформления (light/dark/system) с хранением в prefs.
///
/// Слой: core/theme
/// Зависимости: flutter material, riverpod_annotation,
///   core/storage/preferences_providers.dart.
/// Ключевые типы: ThemeModeController, themeModeControllerProvider.
library;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../storage/preferences_providers.dart';

part 'theme_mode_controller.g.dart';

const String _kThemeModeKey = 'theme_mode';

/// Текущий [ThemeMode], синхронизирован с SharedPreferences.
@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_kThemeModeKey);
    return _decode(raw);
  }

  /// Меняет тему и сохраняет выбор.
  Future<void> setMode(ThemeMode mode) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kThemeModeKey, mode.name);
    state = mode;
  }

  ThemeMode _decode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
}
