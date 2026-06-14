import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';
import 'package:ticket_app/features/scan/domain/ocr/receipt_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/repositories/scan_repository.dart';

/// Валидный PNG (декодируется и Flutter `Image.memory`, и `package:image`) —
/// для widget-тестов и как «байты фото» при сохранении скана.
final Uint8List kValidPngBytes =
    Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

/// Фейк репозитория сканирования: опционально кидает ошибку, фиксирует фото.
class FakeScanRepository implements ScanRepository {
  Object? error;
  String receiptId = 'rid-1';
  Uint8List? receivedPhotoBytes;

  @override
  Future<String> saveScannedReceipt(
    ReceiptDraft draft, {
    Uint8List? photoBytes,
  }) async {
    if (error != null) throw error!;
    receivedPhotoBytes = photoBytes;
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
