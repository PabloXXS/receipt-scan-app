/// Назначение: реализация ScanRepository (сжатие + Storage + insert).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, datasources/scan_remote_datasource.dart,
///   image_compressor.dart, scan_error_mapper.dart,
///   domain/repositories/scan_repository.dart.
/// Ключевые типы: ScanRepositoryImpl, scanRepositoryProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/receipt_draft.dart';
import '../../domain/entities/scan_source.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';
import '../image_compressor.dart';
import '../scan_error_mapper.dart';

/// Создаёт чек из фото: сжатие → загрузка в Storage → insert. Ошибки → ScanFailure.
class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl(this._ds);

  final ScanRemoteDataSource _ds;

  @override
  Future<String> createReceiptFromPhoto(Uint8List photoBytes) async {
    try {
      final compressed = compressReceiptImage(photoBytes);
      final path =
          '${_ds.currentUserId}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _ds.uploadPhoto(path: path, bytes: compressed);
      return await _ds.insertReceipt(
        source: ScanSource.ocr.dbValue,
        photoPath: path,
      );
    } catch (e) {
      throw mapScanException(e);
    }
  }

  @override
  Future<String> saveScannedReceipt(ReceiptDraft draft) async {
    try {
      return await _ds.insertReceiptWithItems(draft);
    } catch (e) {
      throw mapScanException(e);
    }
  }
}

/// DI-провайдер репозитория сканирования.
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepositoryImpl(ref.watch(scanRemoteDataSourceProvider)),
);
