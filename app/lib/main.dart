/// Назначение: точка входа — инициализация Supabase и запуск ProviderScope.
///
/// Слой: bootstrap
/// Зависимости: supabase_flutter, flutter_riverpod, core/config.
/// Ключевые типы: main().
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = SupabaseConfig.fromEnv();
  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  runApp(const ProviderScope(child: ChekiPricesApp()));
}
