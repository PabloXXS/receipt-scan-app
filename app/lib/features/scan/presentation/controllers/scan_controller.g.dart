// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scanControllerHash() => r'4164e17dfe96e90c1dc3430fd79fb8a69781baee';

/// Управляет потоком: фото → upload+insert processing → Realtime → ревью → confirm.
///
/// Copied from [ScanController].
@ProviderFor(ScanController)
final scanControllerProvider =
    AutoDisposeNotifierProvider<ScanController, ScanState>.internal(
  ScanController.new,
  name: r'scanControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scanControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScanController = AutoDisposeNotifier<ScanState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
