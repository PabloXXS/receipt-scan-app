// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scanControllerHash() => r'f9b9aea204c877dffc1e7910140ca67a11327a85';

/// Управляет потоком: захват → OCR → парсинг → ревью → сохранение.
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
