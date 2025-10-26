import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_category.freezed.dart';
part 'item_category.g.dart';

@freezed
class ItemCategory with _$ItemCategory {
  const factory ItemCategory({
    required String id,
    required String name,
    @JsonKey(name: 'parent_id') String? parentId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _ItemCategory;

  factory ItemCategory.fromJson(Map<String, dynamic> json) =>
      _$ItemCategoryFromJson(json);
}

