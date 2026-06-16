// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_details_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$receiptDetailsHash() => r'd524a83a4aa85d33ebed37a606b09a463abef121';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Детали чека по id.
///
/// Copied from [receiptDetails].
@ProviderFor(receiptDetails)
const receiptDetailsProvider = ReceiptDetailsFamily();

/// Детали чека по id.
///
/// Copied from [receiptDetails].
class ReceiptDetailsFamily extends Family<AsyncValue<ReceiptDetails>> {
  /// Детали чека по id.
  ///
  /// Copied from [receiptDetails].
  const ReceiptDetailsFamily();

  /// Детали чека по id.
  ///
  /// Copied from [receiptDetails].
  ReceiptDetailsProvider call(
    String id,
  ) {
    return ReceiptDetailsProvider(
      id,
    );
  }

  @override
  ReceiptDetailsProvider getProviderOverride(
    covariant ReceiptDetailsProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'receiptDetailsProvider';
}

/// Детали чека по id.
///
/// Copied from [receiptDetails].
class ReceiptDetailsProvider extends AutoDisposeFutureProvider<ReceiptDetails> {
  /// Детали чека по id.
  ///
  /// Copied from [receiptDetails].
  ReceiptDetailsProvider(
    String id,
  ) : this._internal(
          (ref) => receiptDetails(
            ref as ReceiptDetailsRef,
            id,
          ),
          from: receiptDetailsProvider,
          name: r'receiptDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$receiptDetailsHash,
          dependencies: ReceiptDetailsFamily._dependencies,
          allTransitiveDependencies:
              ReceiptDetailsFamily._allTransitiveDependencies,
          id: id,
        );

  ReceiptDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<ReceiptDetails> Function(ReceiptDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceiptDetailsProvider._internal(
        (ref) => create(ref as ReceiptDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ReceiptDetails> createElement() {
    return _ReceiptDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptDetailsProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptDetailsRef on AutoDisposeFutureProviderRef<ReceiptDetails> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ReceiptDetailsProviderElement
    extends AutoDisposeFutureProviderElement<ReceiptDetails>
    with ReceiptDetailsRef {
  _ReceiptDetailsProviderElement(super.provider);

  @override
  String get id => (origin as ReceiptDetailsProvider).id;
}

String _$receiptPhotoUrlHash() => r'65ff3c78f54ba966091c140e23ea062d84543cd5';

/// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
///
/// Copied from [receiptPhotoUrl].
@ProviderFor(receiptPhotoUrl)
const receiptPhotoUrlProvider = ReceiptPhotoUrlFamily();

/// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
///
/// Copied from [receiptPhotoUrl].
class ReceiptPhotoUrlFamily extends Family<AsyncValue<String?>> {
  /// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
  ///
  /// Copied from [receiptPhotoUrl].
  const ReceiptPhotoUrlFamily();

  /// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
  ///
  /// Copied from [receiptPhotoUrl].
  ReceiptPhotoUrlProvider call(
    String path,
  ) {
    return ReceiptPhotoUrlProvider(
      path,
    );
  }

  @override
  ReceiptPhotoUrlProvider getProviderOverride(
    covariant ReceiptPhotoUrlProvider provider,
  ) {
    return call(
      provider.path,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'receiptPhotoUrlProvider';
}

/// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
///
/// Copied from [receiptPhotoUrl].
class ReceiptPhotoUrlProvider extends AutoDisposeFutureProvider<String?> {
  /// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
  ///
  /// Copied from [receiptPhotoUrl].
  ReceiptPhotoUrlProvider(
    String path,
  ) : this._internal(
          (ref) => receiptPhotoUrl(
            ref as ReceiptPhotoUrlRef,
            path,
          ),
          from: receiptPhotoUrlProvider,
          name: r'receiptPhotoUrlProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$receiptPhotoUrlHash,
          dependencies: ReceiptPhotoUrlFamily._dependencies,
          allTransitiveDependencies:
              ReceiptPhotoUrlFamily._allTransitiveDependencies,
          path: path,
        );

  ReceiptPhotoUrlProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.path,
  }) : super.internal();

  final String path;

  @override
  Override overrideWith(
    FutureOr<String?> Function(ReceiptPhotoUrlRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ReceiptPhotoUrlProvider._internal(
        (ref) => create(ref as ReceiptPhotoUrlRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        path: path,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String?> createElement() {
    return _ReceiptPhotoUrlProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptPhotoUrlProvider && other.path == path;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptPhotoUrlRef on AutoDisposeFutureProviderRef<String?> {
  /// The parameter `path` of this provider.
  String get path;
}

class _ReceiptPhotoUrlProviderElement
    extends AutoDisposeFutureProviderElement<String?> with ReceiptPhotoUrlRef {
  _ReceiptPhotoUrlProviderElement(super.provider);

  @override
  String get path => (origin as ReceiptPhotoUrlProvider).path;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
