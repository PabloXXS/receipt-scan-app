/// Назначение: реализация ScanRepository (OCR → insert receipts + items).
///
/// Слой: data
/// Фича: scan
/// Зависимости: datasources/scan_remote_datasource.dart,
///   scan_error_mapper.dart, domain/repositories/scan_repository.dart.
/// Ключевые типы: ScanRepositoryImpl, scanRepositoryProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/receipt_draft.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';
import '../scan_error_mapper.dart';

/// Сохраняет распознанный чек через datasource. Ошибки → ScanFailure.
class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl(this._ds);

  final ScanRemoteDataSource _ds;

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
