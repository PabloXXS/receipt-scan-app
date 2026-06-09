import 'dart:convert';
import 'dart:typed_data';

import 'package:ticket_app/features/scan/domain/repositories/scan_repository.dart';

/// Валидный 1×1 PNG — для Image.memory в widget-тестах и как «байты фото».
final Uint8List kValidPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

/// Фейк репозитория сканирования: фиксирует переданные байты, опционально кидает.
class FakeScanRepository implements ScanRepository {
  Object? error;
  Uint8List? lastBytes;
  String receiptId = 'rid-1';

  @override
  Future<String> createReceiptFromPhoto(Uint8List photoBytes) async {
    lastBytes = photoBytes;
    if (error != null) throw error!;
    return receiptId;
  }
}
