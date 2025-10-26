// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemCategory _$ItemCategoryFromJson(Map<String, dynamic> json) {
  return _ItemCategory.fromJson(json);
}

/// @nodoc
mixin _$ItemCategory {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent_id')
  String? get parentId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_deleted')
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this ItemCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemCategoryCopyWith<ItemCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemCategoryCopyWith<$Res> {
  factory $ItemCategoryCopyWith(
          ItemCategory value, $Res Function(ItemCategory) then) =
      _$ItemCategoryCopyWithImpl<$Res, ItemCategory>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted});
}

/// @nodoc
class _$ItemCategoryCopyWithImpl<$Res, $Val extends ItemCategory>
    implements $ItemCategoryCopyWith<$Res> {
  _$ItemCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
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
abstract class _$$ItemCategoryImplCopyWith<$Res>
    implements $ItemCategoryCopyWith<$Res> {
  factory _$$ItemCategoryImplCopyWith(
          _$ItemCategoryImpl value, $Res Function(_$ItemCategoryImpl) then) =
      __$$ItemCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'parent_id') String? parentId,
      @JsonKey(name: 'created_at') DateTime createdAt,
      @JsonKey(name: 'updated_at') DateTime updatedAt,
      @JsonKey(name: 'is_deleted') bool isDeleted});
}

/// @nodoc
class __$$ItemCategoryImplCopyWithImpl<$Res>
    extends _$ItemCategoryCopyWithImpl<$Res, _$ItemCategoryImpl>
    implements _$$ItemCategoryImplCopyWith<$Res> {
  __$$ItemCategoryImplCopyWithImpl(
      _$ItemCategoryImpl _value, $Res Function(_$ItemCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? isDeleted = null,
  }) {
    return _then(_$ItemCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _$ItemCategoryImpl implements _ItemCategory {
  const _$ItemCategoryImpl(
      {required this.id,
      required this.name,
      @JsonKey(name: 'parent_id') this.parentId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'is_deleted') this.isDeleted = false});

  factory _$ItemCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemCategoryImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'parent_id')
  final String? parentId;
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
    return 'ItemCategory(id: $id, name: $name, parentId: $parentId, createdAt: $createdAt, updatedAt: $updatedAt, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
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
      runtimeType, id, name, parentId, createdAt, updatedAt, isDeleted);

  /// Create a copy of ItemCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemCategoryImplCopyWith<_$ItemCategoryImpl> get copyWith =>
      __$$ItemCategoryImplCopyWithImpl<_$ItemCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemCategoryImplToJson(
      this,
    );
  }
}

abstract class _ItemCategory implements ItemCategory {
  const factory _ItemCategory(
      {required final String id,
      required final String name,
      @JsonKey(name: 'parent_id') final String? parentId,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      @JsonKey(name: 'updated_at') required final DateTime updatedAt,
      @JsonKey(name: 'is_deleted') final bool isDeleted}) = _$ItemCategoryImpl;

  factory _ItemCategory.fromJson(Map<String, dynamic> json) =
      _$ItemCategoryImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'parent_id')
  String? get parentId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime get updatedAt;
  @override
  @JsonKey(name: 'is_deleted')
  bool get isDeleted;

  /// Create a copy of ItemCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemCategoryImplCopyWith<_$ItemCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
