import 'dart:convert';
import 'dart:typed_data';

import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';
import 'package:ticket_app/features/scan/domain/ocr/receipt_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/repositories/scan_repository.dart';

/// Валидный 1×1 PNG — для Image.memory в widget-тестах и как «байты фото».
final Uint8List kValidPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Фейк репозитория сканирования: опционально кидает ошибку.
class FakeScanRepository implements ScanRepository {
  Object? error;
  String receiptId = 'rid-1';

  @override
  Future<String> saveScannedReceipt(ReceiptDraft draft) async {
    if (error != null) throw error!;
    return receiptId;
  }
}

/// Фейк выбора фото: отдаёт [result] (или null), либо кидает [error].
class FakePhotoPicker implements PhotoPicker {
  Uint8List? result;
  Object? error;

  Future<Uint8List?> _run() async {
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<Uint8List?> pickFromGallery() => _run();
}

/// Фейк движка OCR — отдаёт заранее заданный результат или кидает [error].
class FakeOcrEngine implements ReceiptOcrEngine {
  FakeOcrEngine(this.result, {this.error});
  final OcrResult result;
  final Object? error;
  @override
  Future<OcrResult> recognize(Uint8List photoBytes) async {
    if (error != null) throw error!;
    return result;
  }
}
