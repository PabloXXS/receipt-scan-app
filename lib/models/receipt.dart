import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt.freezed.dart';
part 'receipt.g.dart';

@freezed
class Receipt with _$Receipt {
  const factory Receipt({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'merchant_name') String? merchantName,
    @JsonKey(name: 'purchase_date') DateTime? purchaseDate,
    @JsonKey(name: 'purchase_time') DateTime? purchaseTime,
    required double total,
    @Default('RUB') String currency,
    @JsonKey(name: 'status') @Default('processing') String status,
    @JsonKey(name: 'source_file_id') String? sourceFileId,
    @JsonKey(name: 'error_text') String? errorText,
    @JsonKey(name: 'store_confidence') double? storeConfidence,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
  }) = _Receipt;

  factory Receipt.fromJson(Map<String, dynamic> json) =>
      _$ReceiptFromJson(json);
}

