/// Назначение: доступ к таблицам receipts/receipt_items и RPC confirm_receipt.
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, supabase_flutter,
///   core/supabase/supabase_providers.dart, domain/entities/scan_source.dart.
/// Ключевые типы: ScanRemoteDataSource (uploadPhoto, insertProcessingReceipt,
///   confirmReceipt), SupabaseScanRemoteDataSource, scanRemoteDataSourceProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/scan_source.dart';

/// Абстракция удалённых операций сканирования.
abstract interface class ScanRemoteDataSource {
  /// Загружает JPEG фото чека в приватный бакет `receipts`. Возвращает путь объекта.
  Future<String> uploadPhoto(Uint8List jpegBytes);

  /// Создаёт «сырой» чек в статусе processing. Возвращает id чека.
  Future<String> insertProcessingReceipt({String? photoPath, String? qrRaw});

  /// Подтверждает чек после ревью через RPC confirm_receipt.
  Future<void> confirmReceipt(
    String receiptId,
    List<Map<String, dynamic>> items,
  );
}

/// Реализация поверх Supabase PostgREST + Storage + RPC.
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
  Future<String> insertProcessingReceipt({
    String? photoPath,
    String? qrRaw,
  }) async {
    final receipt = await _client
        .from('receipts')
        .insert({
          'source': ScanSource.ocr.dbValue,
          'qr_raw': qrRaw,
          'status': 'processing',
          'photo_path': photoPath,
        })
        .select('id')
        .single();
    return receipt['id'] as String;
  }

  @override
  Future<void> confirmReceipt(
    String receiptId,
    List<Map<String, dynamic>> items,
  ) async {
    await _client.rpc('confirm_receipt', params: {
      'p_receipt_id': receiptId,
      'p_items': items,
    });
  }
}

/// DI-провайдер источника данных сканирования.
final scanRemoteDataSourceProvider = Provider<ScanRemoteDataSource>(
  (ref) => SupabaseScanRemoteDataSource(ref.watch(supabaseClientProvider)),
);
