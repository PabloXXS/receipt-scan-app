/// Назначение: доступ к SharedPreferences как Riverpod-провайдер.
///
/// Слой: core/storage
/// Зависимости: flutter_riverpod, shared_preferences.
/// Ключевые типы: sharedPreferencesProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Экземпляр SharedPreferences. Переопределяется в `main.dart` через override.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main()'),
);
