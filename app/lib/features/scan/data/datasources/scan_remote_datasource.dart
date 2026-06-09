/// Назначение: доступ к Supabase Storage и таблице receipts для сканирования.
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, supabase_flutter, core/supabase/supabase_providers.dart.
/// Ключевые типы: ScanRemoteDataSource, SupabaseScanRemoteDataSource,
///   scanRemoteDataSourceProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';

/// Абстракция удалённых операций сканирования.
abstract interface class ScanRemoteDataSource {
  /// id текущего пользователя (для префикса пути в Storage).
  String get currentUserId;

  /// Загружает байты фото в приватный бакет `receipts` по пути [path].
  Future<void> uploadPhoto({required String path, required Uint8List bytes});

  /// Вставляет «сырой» чек и возвращает его id.
  Future<String> insertReceipt({
    required String source,
    required String photoPath,
  });
}

/// Реализация поверх Supabase Storage + PostgREST.
class SupabaseScanRemoteDataSource implements ScanRemoteDataSource {
  const SupabaseScanRemoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  String get currentUserId => _client.auth.currentUser!.id;

  @override
  Future<void> uploadPhoto({
    required String path,
    required Uint8List bytes,
  }) async {
    await _client.storage.from('receipts').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
  }

  @override
  Future<String> insertReceipt({
    required String source,
    required String photoPath,
  }) async {
    final row = await _client
        .from('receipts')
        .insert({'source': source, 'photo_path': photoPath})
        .select('id')
        .single();
    return row['id'] as String;
  }
}

/// DI-провайдер источника данных сканирования.
final scanRemoteDataSourceProvider = Provider<ScanRemoteDataSource>(
  (ref) => SupabaseScanRemoteDataSource(ref.watch(supabaseClientProvider)),
);
