/// Назначение: контракт создания чека из результата сканирования.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data.
/// Ключевые типы: ScanRepository.
library;

import 'dart:typed_data';

/// Контракт сценариев сканирования. Реализация — в слое data.
abstract interface class ScanRepository {
  /// Создаёт чек из фото: сжатие → загрузка в Storage → insert в `receipts`.
  /// Возвращает id созданного чека. Кидает [ScanFailure] при ошибке.
  Future<String> createReceiptFromPhoto(Uint8List photoBytes);

  // TODO(scan-qr): createReceiptFromQr(String raw) — отдельный цикл (скан QR-кода).
}
