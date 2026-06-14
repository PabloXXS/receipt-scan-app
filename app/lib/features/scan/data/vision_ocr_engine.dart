/// Назначение: реализация ReceiptOcrEngine поверх нативного Vision (MethodChannel).
///
/// Слой: data
/// Фича: scan
/// Зависимости: flutter/services (реэкспортирует dart:typed_data), flutter_riverpod,
///   domain/entities/ocr_result.dart, domain/ocr/receipt_ocr_engine.dart.
/// Ключевые типы: VisionOcrEngine, receiptOcrEngineProvider.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr_result.dart';
import '../domain/ocr/receipt_ocr_engine.dart';

/// OCR поверх нативного Apple Vision (канал `scan/ocr`).
class VisionOcrEngine implements ReceiptOcrEngine {
  const VisionOcrEngine();

  static const _channel = MethodChannel('scan/ocr');

  @override
  Future<OcrResult> recognize(Uint8List photoBytes) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      'recognizeReceipt',
      {'bytes': photoBytes},
    );
    final lines = (res?['lines'] as List?)?.cast<String>() ?? const <String>[];
    return OcrResult(lines: lines, qr: res?['qr'] as String?);
  }
}

/// DI-провайдер движка OCR.
final receiptOcrEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const VisionOcrEngine());
