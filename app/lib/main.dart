/// Назначение: точка входа — инициализация Supabase, prefs и запуск ProviderScope.
///
/// Слой: bootstrap
/// Зависимости: supabase_flutter, flutter_riverpod, shared_preferences, core/config.
/// Ключевые типы: main().
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'core/storage/preferences_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnv();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const ChekiPricesApp(),
    ),
  );
}
