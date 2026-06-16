/// Назначение: доступ к receipts/receipt_items и Storage для списка/деталей/удаления.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: flutter_riverpod, supabase_flutter, core/supabase/supabase_providers.dart,
///   models/receipt_dto.dart, domain/entities.
/// Ключевые типы: ReceiptsRemoteDataSource, SupabaseReceiptsRemoteDataSource,
///   receiptsRemoteDataSourceProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_details.dart';
import '../models/receipt_dto.dart';

/// Абстракция удалённых операций со списком/деталями чеков.
abstract interface class ReceiptsRemoteDataSource {
  Future<List<Receipt>> fetchPage({required int limit, required int offset});
  Future<ReceiptDetails> fetchById(String id);
  Future<void> deleteById(String id);
  Future<String?> createPhotoUrl(String path);
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseReceiptsRemoteDataSource implements ReceiptsRemoteDataSource {
  const SupabaseReceiptsRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'receipts';

  @override
  Future<List<Receipt>> fetchPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await _client
        .from('receipts')
        .select(kReceiptColumns)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map((r) => receiptFromRow(r)).toList();
  }

  @override
  Future<ReceiptDetails> fetchById(String id) async {
    final row = await _client
        .from('receipts')
        .select(kReceiptColumns)
        .eq('id', id)
        .single();
    final itemRows = await _client
        .from('receipt_items')
        .select(kReceiptItemColumns)
        .eq('receipt_id', id)
        .order('created_at', ascending: true);
    return ReceiptDetails(
      receipt: receiptFromRow(row),
      items: itemRows.map((r) => receiptItemFromRow(r)).toList(),
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('receipts').delete().eq('id', id);
  }

  @override
  Future<String?> createPhotoUrl(String path) async {
    return _client.storage.from(_bucket).createSignedUrl(path, 3600);
  }
}

/// DI-провайдер источника данных чеков.
final receiptsRemoteDataSourceProvider = Provider<ReceiptsRemoteDataSource>(
  (ref) => SupabaseReceiptsRemoteDataSource(ref.watch(supabaseClientProvider)),
);
