// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$selectedAnalyticsPeriodHash() =>
    r'a4f5d4b62af546a542d871d231e7d4e74b5919d3';

/// Провайдер для выбранного периода аналитики
///
/// Copied from [SelectedAnalyticsPeriod].
@ProviderFor(SelectedAnalyticsPeriod)
final selectedAnalyticsPeriodProvider = AutoDisposeNotifierProvider<
    SelectedAnalyticsPeriod, AnalyticsPeriod>.internal(
  SelectedAnalyticsPeriod.new,
  name: r'selectedAnalyticsPeriodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$selectedAnalyticsPeriodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SelectedAnalyticsPeriod = AutoDisposeNotifier<AnalyticsPeriod>;
String _$timeBasedAnalyticsHash() =>
    r'8de8b3223600c97775f5b3d153928575c15eec2c';

/// Провайдер для данных аналитики за выбранный период
///
/// Copied from [TimeBasedAnalytics].
@ProviderFor(TimeBasedAnalytics)
final timeBasedAnalyticsProvider = AutoDisposeAsyncNotifierProvider<
    TimeBasedAnalytics, AnalyticsPeriodData>.internal(
  TimeBasedAnalytics.new,
  name: r'timeBasedAnalyticsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timeBasedAnalyticsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimeBasedAnalytics = AutoDisposeAsyncNotifier<AnalyticsPeriodData>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
