import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';

import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

import '../../scan_test_fakes.dart';

class FakeScanRemoteDataSource implements ScanRemoteDataSource {
  Object? uploadError;
  Object? insertError;
  final List<String> calls = [];
  String? uploadedPath;

  @override
  String get currentUserId => 'user-1';

  @override
  Future<void> uploadPhoto({
    required String path,
    required Uint8List bytes,
  }) async {
    calls.add('upload');
    uploadedPath = path;
    if (uploadError != null) throw uploadError!;
  }

  @override
  Future<String> insertReceipt({
    required String source,
    required String photoPath,
  }) async {
    calls.add('insert:$source:$photoPath');
    if (insertError != null) throw insertError!;
    return 'rid-1';
  }

  @override
  Future<String> insertReceiptWithItems(ReceiptDraft draft) async {
    throw UnimplementedError();
  }
}

void main() {
  test('успех: сжать → загрузить → вставить, путь {uid}/{ts}.jpg', () async {
    final ds = FakeScanRemoteDataSource();
    final id =
        await ScanRepositoryImpl(ds).createReceiptFromPhoto(kValidPngBytes);

    expect(id, 'rid-1');
    expect(ds.calls.first, 'upload');
    expect(ds.calls[1], startsWith('insert:ocr:'));
    expect(ds.uploadedPath, matches(RegExp(r'^user-1/\d+\.jpg$')));
    expect(ds.calls[1], endsWith(ds.uploadedPath!));
  });

  test('ошибка загрузки → UploadFailure, insert не вызывается', () async {
    final ds = FakeScanRemoteDataSource()
      ..uploadError = const StorageException('x');
    await expectLater(
      () => ScanRepositoryImpl(ds).createReceiptFromPhoto(kValidPngBytes),
      throwsA(isA<UploadFailure>()),
    );
    expect(ds.calls, ['upload']);
  });
}
