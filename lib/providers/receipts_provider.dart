import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../repositories/receipts_repository.dart';

part 'receipts_provider.g.dart';

@riverpod
class Receipts extends _$Receipts {
  @override
  FutureOr<List<Receipt>> build() async {
    return ref.read(receiptsRepositoryProvider).getAllReceipts();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

@riverpod
class ReceiptDetails extends _$ReceiptDetails {
  @override
  FutureOr<(Receipt, List<ReceiptItem>)> build(String receiptId) async {
    final receipt =
        await ref.read(receiptsRepositoryProvider).getReceiptById(receiptId);
    final items =
        await ref.read(receiptsRepositoryProvider).getReceiptItems(receiptId);
    return (receipt, items);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

