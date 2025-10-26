// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceiptItemImpl _$$ReceiptItemImplFromJson(Map<String, dynamic> json) =>
    _$ReceiptItemImpl(
      id: json['id'] as String,
      receiptId: json['receipt_id'] as String,
      name: json['name'] as String,
      quantity: (json['qty'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      categoryId: json['category_id'] as String?,
      categoryName: json['categoryName'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$ReceiptItemImplToJson(_$ReceiptItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'receipt_id': instance.receiptId,
      'name': instance.name,
      'qty': instance.quantity,
      'price': instance.price,
      'category_id': instance.categoryId,
      'categoryName': instance.categoryName,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
