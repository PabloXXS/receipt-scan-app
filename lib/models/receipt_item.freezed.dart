// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReceiptItem _$ReceiptItemFromJson(Map<String, dynamic> json) {
  return _ReceiptItem.fromJson(json);
}

/// @nodoc
mixin _$ReceiptItem {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'receipt_id')
  String get receiptId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty')
  double get quantity => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id')
  String? get categoryId => throw _privateConstructorUsedError;
  String? get categoryName => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ReceiptItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReceiptItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceiptItemCopyWith<ReceiptItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptItemCopyWith<$Res> {
  factory $ReceiptItemCopyWith(
          ReceiptItem value, $Res Function(ReceiptItem) then) =
      _$ReceiptItemCopyWithImpl<$Res, ReceiptItem>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_id') String receiptId,
      String name,
      @JsonKey(name: 'qty') double quantity,
      double price,
      @JsonKey(name: 'category_id') String? categoryId,
      String? categoryName,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class _$ReceiptItemCopyWithImpl<$Res, $Val extends ReceiptItem>
    implements $ReceiptItemCopyWith<$Res> {
  _$ReceiptItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReceiptItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? name = null,
    Object? quantity = null,
    Object? price = null,
    Object? categoryId = freezed,
    Object? categoryName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptId: null == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceiptItemImplCopyWith<$Res>
    implements $ReceiptItemCopyWith<$Res> {
  factory _$$ReceiptItemImplCopyWith(
          _$ReceiptItemImpl value, $Res Function(_$ReceiptItemImpl) then) =
      __$$ReceiptItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'receipt_id') String receiptId,
      String name,
      @JsonKey(name: 'qty') double quantity,
      double price,
      @JsonKey(name: 'category_id') String? categoryId,
      String? categoryName,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt});
}

/// @nodoc
class __$$ReceiptItemImplCopyWithImpl<$Res>
    extends _$ReceiptItemCopyWithImpl<$Res, _$ReceiptItemImpl>
    implements _$$ReceiptItemImplCopyWith<$Res> {
  __$$ReceiptItemImplCopyWithImpl(
      _$ReceiptItemImpl _value, $Res Function(_$ReceiptItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReceiptItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? receiptId = null,
    Object? name = null,
    Object? quantity = null,
    Object? price = null,
    Object? categoryId = freezed,
    Object? categoryName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_$ReceiptItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      receiptId: null == receiptId
          ? _value.receiptId
          : receiptId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      categoryId: freezed == categoryId
          ? _value.categoryId
          : categoryId // ignore: cast_nullable_to_non_nullable
              as String?,
      categoryName: freezed == categoryName
          ? _value.categoryName
          : categoryName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceiptItemImpl implements _ReceiptItem {
  const _$ReceiptItemImpl(
      {required this.id,
      @JsonKey(name: 'receipt_id') required this.receiptId,
      required this.name,
      @JsonKey(name: 'qty') required this.quantity,
      required this.price,
      @JsonKey(name: 'category_id') this.categoryId,
      this.categoryName,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt});

  factory _$ReceiptItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceiptItemImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'receipt_id')
  final String receiptId;
  @override
  final String name;
  @override
  @JsonKey(name: 'qty')
  final double quantity;
  @override
  final double price;
  @override
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @override
  final String? categoryName;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ReceiptItem(id: $id, receiptId: $receiptId, name: $name, quantity: $quantity, price: $price, categoryId: $categoryId, categoryName: $categoryName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceiptItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.receiptId, receiptId) ||
                other.receiptId == receiptId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, receiptId, name, quantity,
      price, categoryId, categoryName, createdAt, updatedAt);

  /// Create a copy of ReceiptItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceiptItemImplCopyWith<_$ReceiptItemImpl> get copyWith =>
      __$$ReceiptItemImplCopyWithImpl<_$ReceiptItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceiptItemImplToJson(
      this,
    );
  }
}

abstract class _ReceiptItem implements ReceiptItem {
  const factory _ReceiptItem(
          {required final String id,
          @JsonKey(name: 'receipt_id') required final String receiptId,
          required final String name,
          @JsonKey(name: 'qty') required final double quantity,
          required final double price,
          @JsonKey(name: 'category_id') final String? categoryId,
          final String? categoryName,
          @JsonKey(name: 'created_at') required final DateTime createdAt,
          @JsonKey(name: 'updated_at') required final DateTime updatedAt}) =
      _$ReceiptItemImpl;

  factory _ReceiptItem.fromJson(Map<String, dynamic> json) =
      _$ReceiptItemImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'receipt_id')
  String get receiptId;
  @override
  String get name;
  @override
  @JsonKey(name: 'qty')
  double get quantity;
  @override
  double get price;
  @override
  @JsonKey(name: 'category_id')
  String? get categoryId;
  @override
  String? get categoryName;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;

  /// Create a copy of ReceiptItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceiptItemImplCopyWith<_$ReceiptItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
