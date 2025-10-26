import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_provider.dart';

final cupertinoThemeProvider = Provider<CupertinoThemeData>((ref) {
  final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
  
  final bool isDark = switch (themeMode) {
    ThemeMode.light => false,
    ThemeMode.dark => true,
    ThemeMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark,
  };

  return CupertinoThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: isDark 
        ? CupertinoColors.systemBackground 
        : CupertinoColors.systemGroupedBackground,
    barBackgroundColor: isDark 
        ? CupertinoColors.systemBackground 
        : CupertinoColors.systemGroupedBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: isDark 
          ? CupertinoColors.label 
          : CupertinoColors.label,
      textStyle: TextStyle(
        color: isDark 
            ? CupertinoColors.label 
            : CupertinoColors.label,
      ),
    ),
    // Явно задаем цвета для навбара
    primaryContrastingColor: isDark 
        ? CupertinoColors.white 
        : CupertinoColors.black,
  );
});
