/// Назначение: сценарий сохранения распознанного чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, entities/receipt_draft.dart,
///   repositories/scan_repository.dart.
/// Ключевые типы: SaveScannedReceipt.
library;

import 'dart:typed_data';

import '../entities/receipt_draft.dart';
import '../repositories/scan_repository.dart';

/// Сохраняет распознанный чек (с опциональным фото). Возвращает id чека.
class SaveScannedReceipt {
  const SaveScannedReceipt(this._repo);
  final ScanRepository _repo;

  Future<String> call(ReceiptDraft draft, {Uint8List? photoBytes}) =>
      _repo.saveScannedReceipt(draft, photoBytes: photoBytes);
}
