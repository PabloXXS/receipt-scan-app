import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/usecases/create_receipt_from_photo.dart';

import '../../scan_test_fakes.dart';

void main() {
  test('передаёт байты в репозиторий и возвращает id чека', () async {
    final repo = FakeScanRepository()..receiptId = 'rid-42';
    final id = await CreateReceiptFromPhoto(repo)(kValidPngBytes);
    expect(id, 'rid-42');
    expect(repo.lastBytes, kValidPngBytes);
  });

  test('пробрасывает ошибку репозитория', () async {
    final repo = FakeScanRepository()..error = const UploadFailureStub();
    expect(
      () => CreateReceiptFromPhoto(repo)(kValidPngBytes),
      throwsA(isA<UploadFailureStub>()),
    );
  });
}

/// Локальная ошибка-маркер для проверки проброса (без привязки к core/error).
class UploadFailureStub implements Exception {
  const UploadFailureStub();
}
