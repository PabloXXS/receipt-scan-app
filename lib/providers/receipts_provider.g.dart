// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$receiptsHash() => r'2c9271af50782f35e93575b76b01b8c34843c6d2';

/// See also [Receipts].
@ProviderFor(Receipts)
final receiptsProvider =
    AutoDisposeAsyncNotifierProvider<Receipts, List<Receipt>>.internal(
  Receipts.new,
  name: r'receiptsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$receiptsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Receipts = AutoDisposeAsyncNotifier<List<Receipt>>;
String _$receiptDetailsHash() => r'bde27277ed8c75220d0f86b72795b77ee7c6af51';

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

abstract class _$ReceiptDetails
    extends BuildlessAutoDisposeAsyncNotifier<(Receipt, List<ReceiptItem>)> {
  late final String receiptId;

  FutureOr<(Receipt, List<ReceiptItem>)> build(
    String receiptId,
  );
}

/// See also [ReceiptDetails].
@ProviderFor(ReceiptDetails)
const receiptDetailsProvider = ReceiptDetailsFamily();

/// See also [ReceiptDetails].
class ReceiptDetailsFamily
    extends Family<AsyncValue<(Receipt, List<ReceiptItem>)>> {
  /// See also [ReceiptDetails].
  const ReceiptDetailsFamily();

  /// See also [ReceiptDetails].
  ReceiptDetailsProvider call(
    String receiptId,
  ) {
    return ReceiptDetailsProvider(
      receiptId,
    );
  }

  @override
  ReceiptDetailsProvider getProviderOverride(
    covariant ReceiptDetailsProvider provider,
  ) {
    return call(
      provider.receiptId,
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

/// See also [ReceiptDetails].
class ReceiptDetailsProvider extends AutoDisposeAsyncNotifierProviderImpl<
    ReceiptDetails, (Receipt, List<ReceiptItem>)> {
  /// See also [ReceiptDetails].
  ReceiptDetailsProvider(
    String receiptId,
  ) : this._internal(
          () => ReceiptDetails()..receiptId = receiptId,
          from: receiptDetailsProvider,
          name: r'receiptDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$receiptDetailsHash,
          dependencies: ReceiptDetailsFamily._dependencies,
          allTransitiveDependencies:
              ReceiptDetailsFamily._allTransitiveDependencies,
          receiptId: receiptId,
        );

  ReceiptDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.receiptId,
  }) : super.internal();

  final String receiptId;

  @override
  FutureOr<(Receipt, List<ReceiptItem>)> runNotifierBuild(
    covariant ReceiptDetails notifier,
  ) {
    return notifier.build(
      receiptId,
    );
  }

  @override
  Override overrideWith(ReceiptDetails Function() create) {
    return ProviderOverride(
      origin: this,
      override: ReceiptDetailsProvider._internal(
        () => create()..receiptId = receiptId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        receiptId: receiptId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ReceiptDetails,
      (Receipt, List<ReceiptItem>)> createElement() {
    return _ReceiptDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ReceiptDetailsProvider && other.receiptId == receiptId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, receiptId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ReceiptDetailsRef
    on AutoDisposeAsyncNotifierProviderRef<(Receipt, List<ReceiptItem>)> {
  /// The parameter `receiptId` of this provider.
  String get receiptId;
}

class _ReceiptDetailsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<ReceiptDetails,
        (Receipt, List<ReceiptItem>)> with ReceiptDetailsRef {
  _ReceiptDetailsProviderElement(super.provider);

  @override
  String get receiptId => (origin as ReceiptDetailsProvider).receiptId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
