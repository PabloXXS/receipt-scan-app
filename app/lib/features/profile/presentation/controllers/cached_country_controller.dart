/// Назначение: локальный кэш кода страны для мгновенного показа в настройках.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: riverpod_annotation, core/storage/preferences_providers.dart.
/// Ключевые типы: CachedCountryController.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/storage/preferences_providers.dart';

part 'cached_country_controller.g.dart';

const String _kCountryCodeKey = 'country_code';

/// Код страны из локального кэша (SharedPreferences). null — ещё не кэширован.
@riverpod
class CachedCountryController extends _$CachedCountryController {
  @override
  String? build() =>
      ref.watch(sharedPreferencesProvider).getString(_kCountryCodeKey);

  /// Сохраняет код страны в кэш (источник истины — профиль).
  Future<void> cache(String code) async {
    if (state == code) return;
    await ref.read(sharedPreferencesProvider).setString(_kCountryCodeKey, code);
    state = code;
  }
}
