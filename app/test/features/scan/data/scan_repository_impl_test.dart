import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';

class _FakeDs implements ScanRemoteDataSource {
  String? uploadedFrom;
  String? insertedPhotoPath;
  String? insertedQr;
  List<Map<String, dynamic>>? confirmedItems;

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    uploadedFrom = 'up';
    return 'uid/ts.jpg';
  }

  @override
  Future<String> insertProcessingReceipt(
      {String? photoPath, String? qrRaw}) async {
    insertedPhotoPath = photoPath;
    insertedQr = qrRaw;
    return 'r1';
  }

  @override
  Future<void> confirmReceipt(
      String id, List<Map<String, dynamic>> items) async {
    confirmedItems = items;
  }
}

void main() {
  test(
      'startScan inserts processing receipt; bad photo bytes -> photoPath null',
      () async {
    final ds = _FakeDs();
    // Uint8List(8) — мусорные байты: processReceiptPhoto бросит FormatException,
    // фото best-effort пропускается (photoPath=null), но чек всё равно создаётся.
    final id = await ScanRepositoryImpl(ds).startScan(
      photoBytes: Uint8List(8),
      qrRaw: 'УИ',
    );
    expect(id, 'r1');
    expect(ds.insertedPhotoPath, isNull);
    expect(ds.uploadedFrom, isNull);
    expect(ds.insertedQr, 'УИ');
  });

  test('confirm forwards items', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds).confirm('r1', [
      {'raw_name': 'A'},
    ]);
    expect(ds.confirmedItems, [
      {'raw_name': 'A'},
    ]);
  });
}
