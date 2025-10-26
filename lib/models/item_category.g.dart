// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemCategoryImpl _$$ItemCategoryImplFromJson(Map<String, dynamic> json) =>
    _$ItemCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ItemCategoryImplToJson(_$ItemCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent_id': instance.parentId,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
    };
