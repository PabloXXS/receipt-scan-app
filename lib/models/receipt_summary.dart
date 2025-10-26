import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_summary.freezed.dart';
part 'receipt_summary.g.dart';

@freezed
class ReceiptSummary with _$ReceiptSummary {
  const factory ReceiptSummary({
    required String id,
    required String title,
    required DateTime createdAt,
    required double total,
    String? merchantId,
    String? merchantName,
    DateTime? purchaseDate,
    DateTime? purchaseTime,
    double? storeConfidence,
  }) = _ReceiptSummary;

  factory ReceiptSummary.fromJson(Map<String, dynamic> json) =>
      _$ReceiptSummaryFromJson(json);
}
