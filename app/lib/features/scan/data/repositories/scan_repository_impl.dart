/// Назначение: реализация ScanRepository (опц. фото → Storage; insert receipts + items).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, core/images/receipt_image_processor.dart,
///   datasources/scan_remote_datasource.dart, scan_error_mapper.dart,
///   domain/repositories/scan_repository.dart.
/// Ключевые типы: ScanRepositoryImpl, scanRepositoryProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/receipt_image_processor.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';
import '../scan_error_mapper.dart';

/// Сохраняет распознанный чек через datasource. Фото — best-effort. Ошибки → ScanFailure.
class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl(this._ds);

  final ScanRemoteDataSource _ds;

  @override
  Future<String> saveScannedReceipt(
    ReceiptDraft draft, {
    Uint8List? photoBytes,
  }) async {
    try {
      String? photoPath;
      if (photoBytes != null) {
        // Best-effort: сжатие или загрузка фото не должны срывать сохранение чека.
        try {
          final jpeg = processReceiptPhoto(photoBytes);
          photoPath = await _ds.uploadPhoto(jpeg);
        } catch (_) {
          photoPath = null;
        }
      }
      return await _ds.insertReceiptWithItems(draft, photoPath: photoPath);
    } catch (e) {
      throw mapScanException(e);
    }
  }
}

/// DI-провайдер репозитория сканирования.
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepositoryImpl(ref.watch(scanRemoteDataSourceProvider)),
);
