import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/qr_scanner.dart';
import 'package:ticket_app/features/scan/domain/repositories/scan_repository.dart';

/// Валидный PNG (декодируется и Flutter `Image.memory`, и `package:image`) —
/// для widget-тестов и как «байты фото» при старте скана.
final Uint8List kValidPngBytes =
    Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

/// Фейк репозитория сканирования: опционально кидает ошибку, фиксирует данные.
class FakeScanRepository implements ScanRepository {
  Object? error;
  String receiptId = 'rid-1';
  Uint8List? receivedPhotoBytes;
  String? receivedQr;
  List<Map<String, dynamic>>? confirmedItems;

  @override
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw}) async {
    if (error != null) throw error!;
    receivedPhotoBytes = photoBytes;
    receivedQr = qrRaw;
    return receiptId;
  }

  @override
  Future<void> confirm(
    String receiptId,
    List<Map<String, dynamic>> items,
  ) async {
    if (error != null) throw error!;
    confirmedItems = items;
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

/// Фейк QR-сканера: отдаёт [result] (по умолчанию null).
class FakeQrScanner implements QrScanner {
  FakeQrScanner({this.result});
  final String? result;

  @override
  Future<String?> scan(Uint8List photoBytes) async => result;
}
