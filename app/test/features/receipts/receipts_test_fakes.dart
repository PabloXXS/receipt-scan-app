import 'dart:math' as math;

import 'package:ticket_app/features/receipts/domain/entities/receipt.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_details.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_item.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';
import 'package:ticket_app/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:ticket_app/features/receipts/domain/repositories/receipts_repository.dart';

/// Удобный конструктор чека для тестов.
Receipt makeReceipt(String id,
        {String? storeName = 'Магазин', double? total = 100}) =>
    Receipt(
      id: id,
      storeName: storeName,
      total: total,
      currency: 'RUB',
      status: ReceiptStatus.done,
      createdAt: DateTime.utc(2026, 6, 14, 10),
      photoPath: null,
    );

/// Фейк datasource: страницы из [all], опционально кидает [error].
class FakeReceiptsRemoteDataSource implements ReceiptsRemoteDataSource {
  FakeReceiptsRemoteDataSource(this.all);
  List<Receipt> all;
  Object? error;
  final List<String> deleted = [];

  @override
  Future<List<Receipt>> fetchPage(
      {required int limit, required int offset}) async {
    if (error != null) throw error!;
    if (offset >= all.length) return [];
    return all.sublist(offset, math.min(offset + limit, all.length));
  }

  @override
  Future<ReceiptDetails> fetchById(String id) async {
    if (error != null) throw error!;
    return ReceiptDetails(
      receipt: all.firstWhere((r) => r.id == id),
      items: const [
        ReceiptItem(id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80)
      ],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    if (error != null) throw error!;
    deleted.add(id);
    all = all.where((r) => r.id != id).toList();
  }

  @override
  Future<String?> createPhotoUrl(String path) async => 'https://signed/$path';
}

/// Фейк репозитория для тестов контроллеров.
class FakeReceiptsRepository implements ReceiptsRepository {
  FakeReceiptsRepository(this.all);
  List<Receipt> all;
  Object? error;
  final List<String> deleted = [];

  @override
  Future<List<Receipt>> list({required int limit, required int offset}) async {
    if (error != null) throw error!;
    if (offset >= all.length) return [];
    return all.sublist(offset, math.min(offset + limit, all.length));
  }

  @override
  Future<ReceiptDetails> getById(String id) async {
    if (error != null) throw error!;
    return ReceiptDetails(
      receipt: all.firstWhere((r) => r.id == id),
      items: const [
        ReceiptItem(id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80)
      ],
    );
  }

  @override
  Future<void> delete(String id) async {
    if (error != null) throw error!;
    deleted.add(id);
    all = all.where((r) => r.id != id).toList();
  }

  @override
  Future<String?> photoUrl(String path) async => 'https://signed/$path';
}
