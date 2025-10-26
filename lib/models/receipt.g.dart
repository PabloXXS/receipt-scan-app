// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceiptImpl _$$ReceiptImplFromJson(Map<String, dynamic> json) =>
    _$ReceiptImpl(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      merchantName: json['merchant_name'] as String?,
      purchaseDate: json['purchase_date'] == null
          ? null
          : DateTime.parse(json['purchase_date'] as String),
      purchaseTime: json['purchase_time'] == null
          ? null
          : DateTime.parse(json['purchase_time'] as String),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'RUB',
      status: json['status'] as String? ?? 'processing',
      sourceFileId: json['source_file_id'] as String?,
      errorText: json['error_text'] as String?,
      storeConfidence: (json['store_confidence'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$ReceiptImplToJson(_$ReceiptImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'merchant_name': instance.merchantName,
      'purchase_date': instance.purchaseDate?.toIso8601String(),
      'purchase_time': instance.purchaseTime?.toIso8601String(),
      'total': instance.total,
      'currency': instance.currency,
      'status': instance.status,
      'source_file_id': instance.sourceFileId,
      'error_text': instance.errorText,
      'store_confidence': instance.storeConfidence,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
    };
