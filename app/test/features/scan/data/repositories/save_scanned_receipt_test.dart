import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

class _FakeDs implements ScanRemoteDataSource {
  Object? error;
  ReceiptDraft? saved;
  @override
  String get currentUserId => 'u1';
  @override
  Future<void> uploadPhoto(
      {required String path, required Uint8List bytes}) async {}
  @override
  Future<String> insertReceipt(
          {required String source, required String photoPath}) async =>
      'x';
  @override
  Future<String> insertReceiptWithItems(ReceiptDraft draft) async {
    saved = draft;
    if (error != null) throw error!;
    return 'rid-9';
  }
}

void main() {
  final draft = const ReceiptDraft(items: [
    ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
  ], total: 2, qrRaw: 'УИ');

  test('saveScannedReceipt передаёт draft и возвращает id', () async {
    final ds = _FakeDs();
    final id = await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(id, 'rid-9');
    expect(ds.saved, same(draft));
  });

  test('ошибка → UploadFailure', () async {
    final ds = _FakeDs()..error = const PostgrestException(message: 'x');
    await expectLater(
      () => ScanRepositoryImpl(ds).saveScannedReceipt(draft),
      throwsA(isA<UploadFailure>()),
    );
  });
}
