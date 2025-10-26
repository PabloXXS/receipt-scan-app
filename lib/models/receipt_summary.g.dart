// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReceiptSummaryImpl _$$ReceiptSummaryImplFromJson(Map<String, dynamic> json) =>
    _$ReceiptSummaryImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      total: (json['total'] as num).toDouble(),
      merchantId: json['merchantId'] as String?,
      merchantName: json['merchantName'] as String?,
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      purchaseTime: json['purchaseTime'] == null
          ? null
          : DateTime.parse(json['purchaseTime'] as String),
      storeConfidence: (json['storeConfidence'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$ReceiptSummaryImplToJson(
        _$ReceiptSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'total': instance.total,
      'merchantId': instance.merchantId,
      'merchantName': instance.merchantName,
      'purchaseDate': instance.purchaseDate?.toIso8601String(),
      'purchaseTime': instance.purchaseTime?.toIso8601String(),
      'storeConfidence': instance.storeConfidence,
    };
