import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_app/core/storage/preferences_providers.dart';
import 'package:ticket_app/core/theme/theme_mode_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> makeContainer(Map<String, Object> seed) async {
    SharedPreferences.setMockInitialValues(seed);
    final prefs = await SharedPreferences.getInstance();
    return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
  }

  test('по умолчанию ThemeMode.system', () async {
    final c = await makeContainer({});
    expect(c.read(themeModeControllerProvider), ThemeMode.system);
  });

  test('читает сохранённое значение', () async {
    final c = await makeContainer({'theme_mode': 'dark'});
    expect(c.read(themeModeControllerProvider), ThemeMode.dark);
  });

  test('setMode обновляет состояние и prefs', () async {
    final c = await makeContainer({});
    await c.read(themeModeControllerProvider.notifier).setMode(ThemeMode.light);
    expect(c.read(themeModeControllerProvider), ThemeMode.light);
  });
}
