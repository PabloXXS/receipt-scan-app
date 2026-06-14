/// Назначение: контракт движка распознавания чека по фото.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, entities/ocr_result.dart.
/// Ключевые типы: ReceiptOcrEngine.
library;

import 'dart:typed_data';

import '../entities/ocr_result.dart';

/// Распознаёт текст и QR чека по байтам фото. Vision-реализация сейчас,
/// LLM-реализация — будущая платная фича.
abstract interface class ReceiptOcrEngine {
  Future<OcrResult> recognize(Uint8List photoBytes);
}
