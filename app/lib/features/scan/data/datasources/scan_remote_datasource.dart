/// Назначение: доступ к таблицам receipts/receipt_items для сохранения OCR-чека.
///
/// Слой: data
/// Фича: scan
/// Зависимости: supabase_flutter, core/supabase/supabase_providers.dart.
/// Ключевые типы: ScanRemoteDataSource, SupabaseScanRemoteDataSource,
///   scanRemoteDataSourceProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/entities/scan_source.dart';

/// Абстракция удалённых операций сканирования.
abstract interface class ScanRemoteDataSource {
  /// Вставляет чек и его позиции (status=done). Возвращает id чека.
  Future<String> insertReceiptWithItems(ReceiptDraft draft);
}

/// Реализация поверх Supabase PostgREST.
class SupabaseScanRemoteDataSource implements ScanRemoteDataSource {
  const SupabaseScanRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<String> insertReceiptWithItems(ReceiptDraft draft) async {
    final receipt = await _client
        .from('receipts')
        .insert({
          'source': ScanSource.ocr.dbValue,
          'qr_raw': draft.qrRaw,
          'status': 'done',
          'total': draft.total,
          'purchased_at': draft.purchasedAt?.toIso8601String(),
        })
        .select('id')
        .single();
    final id = receipt['id'] as String;
    if (draft.items.isNotEmpty) {
      await _client.from('receipt_items').insert([
        for (final it in draft.items)
          {
            'receipt_id': id,
            'raw_name': it.rawName,
            'qty': it.qty,
            'unit_price': it.unitPrice,
            'sum': it.sum,
          },
      ]);
    }
    return id;
  }
}

/// DI-провайдер источника данных сканирования.
final scanRemoteDataSourceProvider = Provider<ScanRemoteDataSource>(
  (ref) => SupabaseScanRemoteDataSource(ref.watch(supabaseClientProvider)),
);
