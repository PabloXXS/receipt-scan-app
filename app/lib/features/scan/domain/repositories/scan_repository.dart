/// Назначение: контракт создания чека из результата сканирования.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: domain/entities/receipt_draft.dart.
/// Ключевые типы: ScanRepository.
library;

import '../entities/receipt_draft.dart';

/// Контракт сценариев сканирования. Реализация — в слое data.
abstract interface class ScanRepository {
  /// Сохраняет распознанный чек: insert receipts + receipt_items. Возвращает id.
  Future<String> saveScannedReceipt(ReceiptDraft draft);

  // TODO(scan-qr): createReceiptFromQr(String raw) — отдельный цикл (скан QR-кода).
}
