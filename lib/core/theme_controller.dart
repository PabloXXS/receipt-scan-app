import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._prefs);

  static const String _prefsKey = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final int? stored = _prefs.getInt(_prefsKey);
    _mode = _intToMode(stored) ?? ThemeMode.system;
  }

  Future<void> setMode(ThemeMode value) async {
    if (_mode == value) return;
    _mode = value;
    await _prefs.setInt(_prefsKey, _mode.index);
    notifyListeners();
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

class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final ThemeControllerProvider? provider =
        context.dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider не найден в дереве');
    return provider!.notifier!;
  }
}
