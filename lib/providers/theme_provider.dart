import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = AsyncNotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  static const String _prefsKey = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? stored = prefs.getInt(_prefsKey);
    return _intToMode(stored) ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, value.index);
    state = AsyncData(value);
  }

  ThemeMode? _intToMode(int? v) {
    if (v == null) return null;
    switch (v) {
      case 0:
        return ThemeMode.system;
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return null;
    }
  }
}
