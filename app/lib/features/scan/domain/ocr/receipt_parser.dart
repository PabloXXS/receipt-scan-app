/// Назначение: контракт парсера строк OCR в черновик чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: entities/ocr_result.dart, entities/receipt_draft.dart.
/// Ключевые типы: ReceiptParser.
library;

import '../entities/ocr_result.dart';
import '../entities/receipt_draft.dart';

/// Преобразует результат OCR в [ReceiptDraft].
abstract interface class ReceiptParser {
  ReceiptDraft parse(OcrResult ocr);
}
