import 'package:freezed_annotation/freezed_annotation.dart';

part 'receipt_item.freezed.dart';
part 'receipt_item.g.dart';

@freezed
class ReceiptItem with _$ReceiptItem {
  const factory ReceiptItem({
    required String id,
    @JsonKey(name: 'receipt_id') required String receiptId,
    required String name,
    @JsonKey(name: 'qty') required double quantity,
    required double price,
    @JsonKey(name: 'category_id') String? categoryId,
    String? categoryName,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _ReceiptItem;

  factory ReceiptItem.fromJson(Map<String, dynamic> json) =>
      _$ReceiptItemFromJson(json);
}

extension ReceiptItemExtension on ReceiptItem {
  double get total => quantity * price;
}
