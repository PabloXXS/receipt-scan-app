// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_wizard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReceiptWizardState {
  ReceiptWizardStep get currentStep => throw _privateConstructorUsedError;
  ReceiptSourceType? get sourceType => throw _privateConstructorUsedError;
  Uint8List? get imageBytes => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get categoryName => throw _privateConstructorUsedError;
  String? get currencyCode => throw _privateConstructorUsedError;
  List<ReceiptItem> get items => throw _privateConstructorUsedError;
  String? get totalAmountText => throw _privateConstructorUsedError;
  bool get isAnalyzing => throw _privateConstructorUsedError;
  String? get errorText => throw _privateConstructorUsedError;
  bool get isSaving => throw _privateConstructorUsedError;
  bool get isPickingImage => throw _privateConstructorUsedError;
  bool get isImagePickCanceled => throw _privateConstructorUsedError;
  String? get receiptId =>
      throw _privateConstructorUsedError; // ID чека для очистки при отмене
  bool get isCancelling =>
      throw _privateConstructorUsedError; // Флаг отмены анализа
  String? get merchantName => throw _privateConstructorUsedError;
  DateTime? get purchaseDate => throw _privateConstructorUsedError;
  DateTime? get purchaseTime => throw _privateConstructorUsedError;

  /// Create a copy of ReceiptWizardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptWizardStateCopyWith<ReceiptWizardState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptWizardStateCopyWith<$Res> {
  factory $ReceiptWizardStateCopyWith(
          ReceiptWizardState value, $Res Function(ReceiptWizardState) then) =
      _$ReceiptWizardStateCopyWithImpl<$Res, ReceiptWizardState>;
  @useResult
  $Res call(
      {ReceiptWizardStep currentStep,
      ReceiptSourceType? sourceType,
      Uint8List? imageBytes,
      String? imageUrl,
      String? categoryName,
      String? currencyCode,
      List<ReceiptItem> items,
      String? totalAmountText,
      bool isAnalyzing,
      String? errorText,
      bool isSaving,
      bool isPickingImage,
      bool isImagePickCanceled,
      String? receiptId,
      bool isCancelling,
      String? merchantName,
      DateTime? purchaseDate,
      DateTime? purchaseTime});
}

/// @nodoc
class _$ReceiptWizardStateCopyWithImpl<$Res, $Val extends ReceiptWizardState>
    implements $ReceiptWizardStateCopyWith<$Res> {
  _$ReceiptWizardStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReceiptWizardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? sourceType = freezed,
    Object? imageBytes = freezed,
    Object? imageUrl = freezed,
    Object? categoryName = freezed,
    Object? currencyCode = freezed,
    Object? items = null,
    Object? totalAmountText = freezed,
    Object? isAnalyzing = null,
    Object? errorText = freezed,
    Object? isSaving = null,
    Object? isPickingImage = null,
    Object? isImagePickCanceled = null,
    Object? receiptId = freezed,
    Object? isCancelling = null,
    Object? merchantName = freezed,
    Object? purchaseDate = freezed,
    Object? purchaseTime = freezed,
  }) {
    return _then(_value.copyWith(
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as ReceiptWizardStep,
      sourceType: freezed == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as ReceiptSourceType?,
      imageBytes: freezed == imageBytes
          ? _value.imageBytes
          : imageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      currencyCode: freezed == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItem>,
      totalAmountText: freezed == totalAmountText
          ? _value.totalAmountText
          : totalAmountText // ignore: cast_nullable_to_non_nullable
              as String?,
      isAnalyzing: null == isAnalyzing
          ? _value.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      errorText: freezed == errorText
          ? _value.errorText
          : errorText // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isPickingImage: null == isPickingImage
          ? _value.isPickingImage
          : isPickingImage // ignore: cast_nullable_to_non_nullable
              as bool,
      isImagePickCanceled: null == isImagePickCanceled
          ? _value.isImagePickCanceled
          : isImagePickCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      receiptId: freezed == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String?,
      isCancelling: null == isCancelling
          ? _value.isCancelling
          : isCancelling // ignore: cast_nullable_to_non_nullable
              as bool,
      merchantName: freezed == merchantName
          ? _value.merchantName
          : merchantName // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: freezed == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      purchaseTime: freezed == purchaseTime
          ? _value.purchaseTime
          : purchaseTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceiptWizardStateImplCopyWith<$Res>
    implements $ReceiptWizardStateCopyWith<$Res> {
  factory _$$ReceiptWizardStateImplCopyWith(_$ReceiptWizardStateImpl value,
          $Res Function(_$ReceiptWizardStateImpl) then) =
      __$$ReceiptWizardStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ReceiptWizardStep currentStep,
      ReceiptSourceType? sourceType,
      Uint8List? imageBytes,
      String? imageUrl,
      String? categoryName,
      String? currencyCode,
      List<ReceiptItem> items,
      String? totalAmountText,
      bool isAnalyzing,
      String? errorText,
      bool isSaving,
      bool isPickingImage,
      bool isImagePickCanceled,
      String? receiptId,
      bool isCancelling,
      String? merchantName,
      DateTime? purchaseDate,
      DateTime? purchaseTime});
}

/// @nodoc
class __$$ReceiptWizardStateImplCopyWithImpl<$Res>
    extends _$ReceiptWizardStateCopyWithImpl<$Res, _$ReceiptWizardStateImpl>
    implements _$$ReceiptWizardStateImplCopyWith<$Res> {
  __$$ReceiptWizardStateImplCopyWithImpl(_$ReceiptWizardStateImpl _value,
      $Res Function(_$ReceiptWizardStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReceiptWizardState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? sourceType = freezed,
    Object? imageBytes = freezed,
    Object? imageUrl = freezed,
    Object? categoryName = freezed,
    Object? currencyCode = freezed,
    Object? items = null,
    Object? totalAmountText = freezed,
    Object? isAnalyzing = null,
    Object? errorText = freezed,
    Object? isSaving = null,
    Object? isPickingImage = null,
    Object? isImagePickCanceled = null,
    Object? receiptId = freezed,
    Object? isCancelling = null,
    Object? merchantName = freezed,
    Object? purchaseDate = freezed,
    Object? purchaseTime = freezed,
  }) {
    return _then(_$ReceiptWizardStateImpl(
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as ReceiptWizardStep,
      sourceType: freezed == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as ReceiptSourceType?,
      imageBytes: freezed == imageBytes
          ? _value.imageBytes
          : imageBytes // ignore: cast_nullable_to_non_nullable
              as Uint8List?,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      currencyCode: freezed == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String?,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ReceiptItem>,
      totalAmountText: freezed == totalAmountText
          ? _value.totalAmountText
          : totalAmountText // ignore: cast_nullable_to_non_nullable
              as String?,
      isAnalyzing: null == isAnalyzing
          ? _value.isAnalyzing
          : isAnalyzing // ignore: cast_nullable_to_non_nullable
              as bool,
      errorText: freezed == errorText
          ? _value.errorText
          : errorText // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaving: null == isSaving
          ? _value.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isPickingImage: null == isPickingImage
          ? _value.isPickingImage
          : isPickingImage // ignore: cast_nullable_to_non_nullable
              as bool,
      isImagePickCanceled: null == isImagePickCanceled
          ? _value.isImagePickCanceled
          : isImagePickCanceled // ignore: cast_nullable_to_non_nullable
              as bool,
      receiptId: freezed == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String?,
      isCancelling: null == isCancelling
          ? _value.isCancelling
          : isCancelling // ignore: cast_nullable_to_non_nullable
              as bool,
      merchantName: freezed == merchantName
          ? _value.merchantName
          : merchantName // ignore: cast_nullable_to_non_nullable
              as String?,
      purchaseDate: freezed == purchaseDate
          ? _value.purchaseDate
          : purchaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      purchaseTime: freezed == purchaseTime
          ? _value.purchaseTime
          : purchaseTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$ReceiptWizardStateImpl implements _ReceiptWizardState {
  const _$ReceiptWizardStateImpl(
      {this.currentStep = ReceiptWizardStep.preview,
      this.sourceType = null,
      this.imageBytes = null,
      this.imageUrl = null,
      this.categoryName = null,
      this.currencyCode = null,
      final List<ReceiptItem> items = const [],
      this.totalAmountText = null,
      this.isAnalyzing = false,
      this.errorText = null,
      this.isSaving = false,
      this.isPickingImage = false,
      this.isImagePickCanceled = false,
      this.receiptId = null,
      this.isCancelling = false,
      this.merchantName = null,
      this.purchaseDate = null,
      this.purchaseTime = null})
      : _items = items;

  @override
  @JsonKey()
  final ReceiptWizardStep currentStep;
  @override
  @JsonKey()
  final ReceiptSourceType? sourceType;
  @override
  @JsonKey()
  final Uint8List? imageBytes;
  @override
  @JsonKey()
  final String? imageUrl;
  @override
  @JsonKey()
  final String? categoryName;
  @override
  @JsonKey()
  final String? currencyCode;
  final List<ReceiptItem> _items;
  @override
  @JsonKey()
  List<ReceiptItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey()
  final String? totalAmountText;
  @override
  @JsonKey()
  final bool isAnalyzing;
  @override
  @JsonKey()
  final String? errorText;
  @override
  @JsonKey()
  final bool isSaving;
  @override
  @JsonKey()
  final bool isPickingImage;
  @override
  @JsonKey()
  final bool isImagePickCanceled;
  @override
  @JsonKey()
  final String? receiptId;
// ID чека для очистки при отмене
  @override
  @JsonKey()
  final bool isCancelling;
// Флаг отмены анализа
  @override
  @JsonKey()
  final String? merchantName;
  @override
  @JsonKey()
  final DateTime? purchaseDate;
  @override
  @JsonKey()
  final DateTime? purchaseTime;

  @override
  String toString() {
    return 'ReceiptWizardState(currentStep: $currentStep, sourceType: $sourceType, imageBytes: $imageBytes, imageUrl: $imageUrl, categoryName: $categoryName, currencyCode: $currencyCode, items: $items, totalAmountText: $totalAmountText, isAnalyzing: $isAnalyzing, errorText: $errorText, isSaving: $isSaving, isPickingImage: $isPickingImage, isImagePickCanceled: $isImagePickCanceled, receiptId: $receiptId, isCancelling: $isCancelling, merchantName: $merchantName, purchaseDate: $purchaseDate, purchaseTime: $purchaseTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptWizardStateImpl &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            const DeepCollectionEquality()
                .equals(other.imageBytes, imageBytes) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.totalAmountText, totalAmountText) ||
                other.totalAmountText == totalAmountText) &&
            (identical(other.isAnalyzing, isAnalyzing) ||
                other.isAnalyzing == isAnalyzing) &&
            (identical(other.errorText, errorText) ||
                other.errorText == errorText) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.isPickingImage, isPickingImage) ||
                other.isPickingImage == isPickingImage) &&
            (identical(other.isImagePickCanceled, isImagePickCanceled) ||
                other.isImagePickCanceled == isImagePickCanceled) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.isCancelling, isCancelling) ||
                other.isCancelling == isCancelling) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.purchaseTime, purchaseTime) ||
                other.purchaseTime == purchaseTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentStep,
      sourceType,
      const DeepCollectionEquality().hash(imageBytes),
      imageUrl,
      categoryName,
      currencyCode,
      const DeepCollectionEquality().hash(_items),
      totalAmountText,
      isAnalyzing,
      errorText,
      isSaving,
      isPickingImage,
      isImagePickCanceled,
      receiptId,
      isCancelling,
      merchantName,
      purchaseDate,
      purchaseTime);

  /// Create a copy of ReceiptWizardState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptWizardStateImplCopyWith<_$ReceiptWizardStateImpl> get copyWith =>
      __$$ReceiptWizardStateImplCopyWithImpl<_$ReceiptWizardStateImpl>(
          this, _$identity);
}

abstract class _ReceiptWizardState implements ReceiptWizardState {
  const factory _ReceiptWizardState(
      {final ReceiptWizardStep currentStep,
      final ReceiptSourceType? sourceType,
      final Uint8List? imageBytes,
      final String? imageUrl,
      final String? categoryName,
      final String? currencyCode,
      final List<ReceiptItem> items,
      final String? totalAmountText,
      final bool isAnalyzing,
      final String? errorText,
      final bool isSaving,
      final bool isPickingImage,
      final bool isImagePickCanceled,
      final String? receiptId,
      final bool isCancelling,
      final String? merchantName,
      final DateTime? purchaseDate,
      final DateTime? purchaseTime}) = _$ReceiptWizardStateImpl;

  @override
  ReceiptWizardStep get currentStep;
  @override
  ReceiptSourceType? get sourceType;
  @override
  Uint8List? get imageBytes;
  @override
  String? get imageUrl;
  @override
  String? get categoryName;
  @override
  String? get currencyCode;
  @override
  List<ReceiptItem> get items;
  @override
  String? get totalAmountText;
  @override
  bool get isAnalyzing;
  @override
  String? get errorText;
  @override
  bool get isSaving;
  @override
  bool get isPickingImage;
  @override
  bool get isImagePickCanceled;
  @override
  String? get receiptId; // ID чека для очистки при отмене
  @override
  bool get isCancelling; // Флаг отмены анализа
  @override
  String? get merchantName;
  @override
  DateTime? get purchaseDate;
  @override
  DateTime? get purchaseTime;

  /// Create a copy of ReceiptWizardState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptWizardStateImplCopyWith<_$ReceiptWizardStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
