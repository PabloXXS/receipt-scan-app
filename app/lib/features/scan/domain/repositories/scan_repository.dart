/// Назначение: контракт создания чека из результата сканирования.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, domain/entities/receipt_draft.dart.
/// Ключевые типы: ScanRepository.
library;

import 'dart:typed_data';

import '../entities/receipt_draft.dart';

/// Контракт сценариев сканирования. Реализация — в слое data.
abstract interface class ScanRepository {
  /// Сохраняет распознанный чек: (опц.) загрузка фото в Storage → insert
  /// receipts + receipt_items. Возвращает id чека.
  Future<String> saveScannedReceipt(ReceiptDraft draft,
      {Uint8List? photoBytes});

  // TODO(scan-qr): createReceiptFromQr(String raw) — отдельный цикл (скан QR-кода).
}
