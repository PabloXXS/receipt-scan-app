/// Назначение: сценарий сохранения распознанного чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: entities/receipt_draft.dart, repositories/scan_repository.dart.
/// Ключевые типы: SaveScannedReceipt.
library;

import '../entities/receipt_draft.dart';
import '../repositories/scan_repository.dart';

/// Сохраняет распознанный чек. Возвращает id чека.
class SaveScannedReceipt {
  const SaveScannedReceipt(this._repo);
  final ScanRepository _repo;

  Future<String> call(ReceiptDraft draft) => _repo.saveScannedReceipt(draft);
}
