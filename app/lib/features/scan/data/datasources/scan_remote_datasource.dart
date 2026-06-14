/// Назначение: доступ к таблицам receipts/receipt_items для сохранения OCR-чека.
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, supabase_flutter,
///   core/supabase/supabase_providers.dart.
/// Ключевые типы: ScanRemoteDataSource (uploadPhoto, insertReceiptWithItems),
///   SupabaseScanRemoteDataSource, scanRemoteDataSourceProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/entities/scan_source.dart';

/// Абстракция удалённых операций сканирования.
abstract interface class ScanRemoteDataSource {
  /// Загружает JPEG фото чека в приватный бакет `receipts`. Возвращает путь объекта.
  Future<String> uploadPhoto(Uint8List jpegBytes);

  /// Вставляет чек и его позиции (status=done). Возвращает id чека.
  Future<String> insertReceiptWithItems(ReceiptDraft draft,
      {String? photoPath});
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseScanRemoteDataSource implements ScanRemoteDataSource {
  const SupabaseScanRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'receipts';

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          jpegBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<String> insertReceiptWithItems(
    ReceiptDraft draft, {
    String? photoPath,
  }) async {
    final receipt = await _client
        .from('receipts')
        .insert({
          'source': ScanSource.ocr.dbValue,
          'qr_raw': draft.qrRaw,
          'status': 'done',
          'total': draft.total,
          'purchased_at': draft.purchasedAt?.toIso8601String(),
          'photo_path': photoPath,
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
