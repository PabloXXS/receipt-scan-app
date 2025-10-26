// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Receipt _$ReceiptFromJson(Map<String, dynamic> json) {
  return _Receipt.fromJson(json);
}

/// @nodoc
mixin _$Receipt {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'merchant_name')
  String? get merchantName => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_date')
  DateTime? get purchaseDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'purchase_time')
  DateTime? get purchaseTime => throw _privateConstructorUsedError;
  double get total => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  @JsonKey(name: 'status')
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'source_file_id')
  String? get sourceFileId => throw _privateConstructorUsedError;
  @JsonKey(name: 'error_text')
  String? get errorText => throw _privateConstructorUsedError;
  @JsonKey(name: 'store_confidence')
  double? get storeConfidence => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this Receipt to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptCopyWith<Receipt> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptCopyWith<$Res> {
  factory $ReceiptCopyWith(Receipt value, $Res Function(Receipt) then) =
      _$ReceiptCopyWithImpl<$Res, Receipt>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'merchant_name') String? merchantName,
      @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
      @JsonKey(name: 'purchase_time') DateTime? purchaseTime,
      double total,
      String currency,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'source_file_id') String? sourceFileId,
      @JsonKey(name: 'error_text') String? errorText,
      @JsonKey(name: 'store_confidence') double? storeConfidence,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted});
}

/// @nodoc
class _$ReceiptCopyWithImpl<$Res, $Val extends Receipt>
    implements $ReceiptCopyWith<$Res> {
  _$ReceiptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? merchantName = freezed,
    Object? purchaseDate = freezed,
    Object? purchaseTime = freezed,
    Object? total = null,
    Object? currency = null,
    Object? status = null,
    Object? sourceFileId = freezed,
    Object? errorText = freezed,
    Object? storeConfidence = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
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
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      sourceFileId: freezed == sourceFileId
          ? _value.sourceFileId
          : sourceFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorText: freezed == errorText
          ? _value.errorText
          : errorText // ignore: cast_nullable_to_non_nullable
              as String?,
      storeConfidence: freezed == storeConfidence
          ? _value.storeConfidence
          : storeConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceiptImplCopyWith<$Res> implements $ReceiptCopyWith<$Res> {
  factory _$$ReceiptImplCopyWith(
          _$ReceiptImpl value, $Res Function(_$ReceiptImpl) then) =
      __$$ReceiptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String userId,
      @JsonKey(name: 'merchant_name') String? merchantName,
      @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
      @JsonKey(name: 'purchase_time') DateTime? purchaseTime,
      double total,
      String currency,
      @JsonKey(name: 'status') String status,
      @JsonKey(name: 'source_file_id') String? sourceFileId,
      @JsonKey(name: 'error_text') String? errorText,
      @JsonKey(name: 'store_confidence') double? storeConfidence,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted});
}

/// @nodoc
class __$$ReceiptImplCopyWithImpl<$Res>
    extends _$ReceiptCopyWithImpl<$Res, _$ReceiptImpl>
    implements _$$ReceiptImplCopyWith<$Res> {
  __$$ReceiptImplCopyWithImpl(
      _$ReceiptImpl _value, $Res Function(_$ReceiptImpl) _then)
      : super(_value, _then);

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? merchantName = freezed,
    Object? purchaseDate = freezed,
    Object? purchaseTime = freezed,
    Object? total = null,
    Object? currency = null,
    Object? status = null,
    Object? sourceFileId = freezed,
    Object? errorText = freezed,
    Object? storeConfidence = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(_$ReceiptImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
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
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as double,
      currency: null == currency
          ? _value.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      sourceFileId: freezed == sourceFileId
          ? _value.sourceFileId
          : sourceFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      errorText: freezed == errorText
          ? _value.errorText
          : errorText // ignore: cast_nullable_to_non_nullable
              as String?,
      storeConfidence: freezed == storeConfidence
          ? _value.storeConfidence
          : storeConfidence // ignore: cast_nullable_to_non_nullable
              as double?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isDeleted: null == isDeleted
          ? _value.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceiptImpl implements _Receipt {
  const _$ReceiptImpl(
      {required this.id,
      @JsonKey(name: 'user_id') required this.userId,
      @JsonKey(name: 'merchant_name') this.merchantName,
      @JsonKey(name: 'purchase_date') this.purchaseDate,
      @JsonKey(name: 'purchase_time') this.purchaseTime,
      required this.total,
      this.currency = 'RUB',
      @JsonKey(name: 'status') this.status = 'processing',
      @JsonKey(name: 'source_file_id') this.sourceFileId,
      @JsonKey(name: 'error_text') this.errorText,
      @JsonKey(name: 'store_confidence') this.storeConfidence,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'is_deleted') this.isDeleted = false});

  factory _$ReceiptImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceiptImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'merchant_name')
  final String? merchantName;
  @override
  @JsonKey(name: 'purchase_date')
  final DateTime? purchaseDate;
  @override
  @JsonKey(name: 'purchase_time')
  final DateTime? purchaseTime;
  @override
  final double total;
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey(name: 'status')
  final String status;
  @override
  @JsonKey(name: 'source_file_id')
  final String? sourceFileId;
  @override
  @JsonKey(name: 'error_text')
  final String? errorText;
  @override
  @JsonKey(name: 'store_confidence')
  final double? storeConfidence;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @override
  @JsonKey(name: 'is_deleted')
  final bool isDeleted;

  @override
  String toString() {
    return 'Receipt(id: $id, userId: $userId, merchantName: $merchantName, purchaseDate: $purchaseDate, purchaseTime: $purchaseTime, total: $total, currency: $currency, status: $status, sourceFileId: $sourceFileId, errorText: $errorText, storeConfidence: $storeConfidence, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.purchaseDate, purchaseDate) ||
                other.purchaseDate == purchaseDate) &&
            (identical(other.purchaseTime, purchaseTime) ||
                other.purchaseTime == purchaseTime) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.sourceFileId, sourceFileId) ||
                other.sourceFileId == sourceFileId) &&
            (identical(other.errorText, errorText) ||
                other.errorText == errorText) &&
            (identical(other.storeConfidence, storeConfidence) ||
                other.storeConfidence == storeConfidence) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      merchantName,
      purchaseDate,
      purchaseTime,
      total,
      currency,
      status,
      sourceFileId,
      errorText,
      storeConfidence,
      createdAt,
      updatedAt,
      isDeleted);

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptImplCopyWith<_$ReceiptImpl> get copyWith =>
      __$$ReceiptImplCopyWithImpl<_$ReceiptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceiptImplToJson(
      this,
    );
  }
}

abstract class _Receipt implements Receipt {
  const factory _Receipt(
      {required final String id,
      @JsonKey(name: 'user_id') required final String userId,
      @JsonKey(name: 'merchant_name') final String? merchantName,
      @JsonKey(name: 'purchase_date') final DateTime? purchaseDate,
      @JsonKey(name: 'purchase_time') final DateTime? purchaseTime,
      required final double total,
      final String currency,
      @JsonKey(name: 'status') final String status,
      @JsonKey(name: 'source_file_id') final String? sourceFileId,
      @JsonKey(name: 'error_text') final String? errorText,
      @JsonKey(name: 'store_confidence') final double? storeConfidence,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'is_deleted') final bool isDeleted}) = _$ReceiptImpl;

  factory _Receipt.fromJson(Map<String, dynamic> json) = _$ReceiptImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'merchant_name')
  String? get merchantName;
  @override
  @JsonKey(name: 'purchase_date')
  DateTime? get purchaseDate;
  @override
  @JsonKey(name: 'purchase_time')
  DateTime? get purchaseTime;
  @override
  double get total;
  @override
  String get currency;
  @override
  @JsonKey(name: 'status')
  String get status;
  @override
  @JsonKey(name: 'source_file_id')
  String? get sourceFileId;
  @override
  @JsonKey(name: 'error_text')
  String? get errorText;
  @override
  @JsonKey(name: 'store_confidence')
  double? get storeConfidence;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;

  /// Create a copy of Receipt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptImplCopyWith<_$ReceiptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
