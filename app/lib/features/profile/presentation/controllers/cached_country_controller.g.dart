// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_country_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cachedCountryControllerHash() =>
    r'0fc4e0b9646521adf5afa7dc58b218988554c02d';

/// Код страны из локального кэша (SharedPreferences). null — ещё не кэширован.
///
/// Copied from [CachedCountryController].
@ProviderFor(CachedCountryController)
final cachedCountryControllerProvider =
    AutoDisposeNotifierProvider<CachedCountryController, String?>.internal(
  CachedCountryController.new,
  name: r'cachedCountryControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedCountryControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CachedCountryController = AutoDisposeNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
