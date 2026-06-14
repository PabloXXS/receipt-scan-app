import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

import '../../scan_test_fakes.dart';

class _FakeDs implements ScanRemoteDataSource {
  Object? error; // ошибка insert
  Object? uploadError; // ошибка upload
  ReceiptDraft? saved;
  String? insertedPhotoPath;
  int uploadCalls = 0;

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    uploadCalls++;
    if (uploadError != null) throw uploadError!;
    return 'uid/123.jpg';
  }

  @override
  Future<String> insertReceiptWithItems(
    ReceiptDraft draft, {
    String? photoPath,
  }) async {
    saved = draft;
    insertedPhotoPath = photoPath;
    if (error != null) throw error!;
    return 'rid-9';
  }
}

void main() {
  const draft = ReceiptDraft(items: [
    ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
  ], total: 2, qrRaw: 'УИ');

  test('saveScannedReceipt передаёт draft и возвращает id', () async {
    final ds = _FakeDs();
    final id = await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(id, 'rid-9');
    expect(ds.saved, same(draft));
  });

  test('без photoBytes upload не вызывается, photoPath=null', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(ds.uploadCalls, 0);
    expect(ds.insertedPhotoPath, isNull);
  });

  test('с photoBytes: фото грузится, путь попадает в insert', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds)
        .saveScannedReceipt(draft, photoBytes: kValidPngBytes);
    expect(ds.uploadCalls, 1);
    expect(ds.insertedPhotoPath, 'uid/123.jpg');
  });

  test('ошибка загрузки фото → чек сохраняется без фото (best-effort)',
      () async {
    final ds = _FakeDs()..uploadError = const StorageException('boom');
    final id = await ScanRepositoryImpl(ds)
        .saveScannedReceipt(draft, photoBytes: kValidPngBytes);
    expect(id, 'rid-9');
    expect(ds.insertedPhotoPath, isNull);
  });

  test('ошибка insert → UploadFailure', () async {
    final ds = _FakeDs()..error = const PostgrestException(message: 'x');
    await expectLater(
      () => ScanRepositoryImpl(ds).saveScannedReceipt(draft),
      throwsA(isA<UploadFailure>()),
    );
  });
}
