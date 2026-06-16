/// Назначение: контракт async-сканирования — старт обработки и подтверждение.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data.
/// Ключевые типы: ScanRepository.
library;

import 'dart:typed_data';

/// Контракт сценариев сканирования. Реализация — в слое data.
abstract interface class ScanRepository {
  /// Загружает фото (best-effort) и создаёт чек в processing. Возвращает id.
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw});

  /// Подтверждает распознанный чек после ревью (RPC confirm_receipt).
  Future<void> confirm(String receiptId, List<Map<String, dynamic>> items);
}
