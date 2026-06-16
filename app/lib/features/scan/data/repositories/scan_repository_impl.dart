/// Назначение: реализация ScanRepository — старт processing-чека и confirm_receipt.
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
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';
import '../scan_error_mapper.dart';

/// Старт обработки чека и подтверждение через datasource. Ошибки → ScanFailure.
class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl(this._ds);

  final ScanRemoteDataSource _ds;

  @override
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw}) async {
    try {
      String? photoPath;
      if (photoBytes != null) {
        // Best-effort: сжатие или загрузка фото не должны срывать создание чека.
        try {
          final jpeg = processReceiptPhoto(photoBytes);
          photoPath = await _ds.uploadPhoto(jpeg);
        } catch (_) {
          photoPath = null;
        }
      }
      return await _ds.insertProcessingReceipt(
        photoPath: photoPath,
        qrRaw: qrRaw,
      );
    } catch (e) {
      throw mapScanException(e);
    }
  }

  @override
  Future<void> confirm(
    String receiptId,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      await _ds.confirmReceipt(receiptId, items);
    } catch (e) {
      throw mapScanException(e);
    }
  }
}

/// DI-провайдер репозитория сканирования.
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepositoryImpl(ref.watch(scanRemoteDataSourceProvider)),
);
