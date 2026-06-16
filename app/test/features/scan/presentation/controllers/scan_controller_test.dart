import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/core/realtime/receipt_realtime.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipts_list_controller.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/qr_scanner.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/presentation/controllers/scan_controller.dart';

import '../../../receipts/receipts_test_fakes.dart';
import '../../scan_test_fakes.dart';

/// Realtime-фейк: статус чека эмитим вручную через [emitStatus],
/// позиции — заранее заданные строки.
class _FakeRealtime implements ReceiptRealtime {
  _FakeRealtime({this.itemRows = const []});

  final _receipt = StreamController<List<Map<String, dynamic>>>.broadcast();
  final List<Map<String, dynamic>> itemRows;

  void emitStatus(String id, String status) => _receipt.add([
        {'id': id, 'status': status}
      ]);

  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) => _receipt.stream;

  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) =>
      Stream.value(itemRows);
}

ProviderContainer _c({
  FakePhotoPicker? picker,
  FakeScanRepository? repo,
  _FakeRealtime? realtime,
  FakeQrScanner? qr,
}) {
  final c = ProviderContainer(overrides: [
    photoPickerProvider.overrideWithValue(
        picker ?? (FakePhotoPicker()..result = kValidPngBytes)),
    scanRepositoryProvider.overrideWithValue(repo ?? FakeScanRepository()),
    receiptRealtimeProvider.overrideWithValue(realtime ?? _FakeRealtime()),
    qrScannerProvider.overrideWithValue(qr ?? FakeQrScanner()),
  ]);
  addTearDown(c.dispose);
  // Держим контроллер «живым»: он autoDispose, и без активного слушателя
  // сбрасывается к ScanIdle после асинхронных пауз в тесте.
  final sub = c.listen(scanControllerProvider, (_, __) {});
  addTearDown(sub.close);
  return c;
}

void main() {
  test('начальное состояние — ScanIdle', () {
    expect(_c().read(scanControllerProvider), isA<ScanIdle>());
  });

  test('photo -> uploading -> processing -> review -> saved', () async {
    final repo = FakeScanRepository()..receiptId = 'r1';
    final rt = _FakeRealtime(itemRows: [
      {
        'raw_name': 'Молоко',
        'qty': 1,
        'unit_price': 2.5,
        'sum': 2.5,
        'confidence': 0.9,
      },
    ]);
    final c = _c(repo: repo, realtime: rt);
    final n = c.read(scanControllerProvider.notifier);

    await n.recognizePhoto(Uint8List(8));
    expect(c.read(scanControllerProvider), isA<ScanProcessing>());

    rt.emitStatus('r1', 'review');
    await Future<void>.delayed(Duration.zero);
    final review = c.read(scanControllerProvider);
    expect(review, isA<ScanReview>());
    expect((review as ScanReview).items.single.rawName, 'Молоко');

    await n.confirm();
    expect(c.read(scanControllerProvider), isA<ScanSaved>());
    expect(repo.confirmedItems!.single['raw_name'], 'Молоко');
  });

  test('status=failed → ScanError', () async {
    final rt = _FakeRealtime();
    final c = _c(repo: FakeScanRepository()..receiptId = 'r1', realtime: rt);
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(Uint8List(8));
    rt.emitStatus('r1', 'failed');
    await Future<void>.delayed(Duration.zero);
    expect(c.read(scanControllerProvider), isA<ScanError>());
  });

  test('ошибка startScan → ScanError', () async {
    final c = _c(repo: FakeScanRepository()..error = const UploadFailure());
    await c.read(scanControllerProvider.notifier).recognizePhoto(Uint8List(8));
    expect(c.read(scanControllerProvider), isA<ScanError>());
  });

  test('pickFromGallery с фото → ScanProcessing', () async {
    final c = _c(picker: FakePhotoPicker()..result = kValidPngBytes);
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanProcessing>());
  });

  test('отмена выбора (null) → остаётся ScanIdle', () async {
    final c = _c(picker: FakePhotoPicker());
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });

  test('removeItem убирает позицию из ревью', () async {
    final rt = _FakeRealtime(itemRows: [
      {'raw_name': 'A', 'qty': 1, 'unit_price': 1, 'sum': 1},
      {'raw_name': 'B', 'qty': 1, 'unit_price': 1, 'sum': 1},
    ]);
    final c = _c(repo: FakeScanRepository()..receiptId = 'r1', realtime: rt);
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(Uint8List(8));
    rt.emitStatus('r1', 'review');
    await Future<void>.delayed(Duration.zero);
    n.removeItem(0);
    expect((c.read(scanControllerProvider) as ScanReview).items.length, 1);
  });

  test('confirm() инвалидирует список чеков → новый чек виден без refresh',
      () async {
    final receiptsRepo = FakeReceiptsRepository([]);
    final rt = _FakeRealtime(itemRows: [
      {'raw_name': 'A', 'qty': 1, 'unit_price': 1, 'sum': 1},
    ]);
    final c = ProviderContainer(overrides: [
      photoPickerProvider
          .overrideWithValue(FakePhotoPicker()..result = kValidPngBytes),
      scanRepositoryProvider
          .overrideWithValue(FakeScanRepository()..receiptId = 'r1'),
      receiptRealtimeProvider.overrideWithValue(rt),
      qrScannerProvider.overrideWithValue(FakeQrScanner()),
      receiptsRepositoryProvider.overrideWithValue(receiptsRepo),
    ]);
    addTearDown(c.dispose);
    // Держим список «живым» — иначе autoDispose сам перезапросит данные при
    // повторном чтении, и тест прошёл бы даже без инвалидации (ложный успех).
    final sub = c.listen(receiptsListControllerProvider, (_, __) {});
    addTearDown(sub.close);
    final scanSub = c.listen(scanControllerProvider, (_, __) {});
    addTearDown(scanSub.close);

    final initial = await c.read(receiptsListControllerProvider.future);
    expect(initial.items, isEmpty);

    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes);
    rt.emitStatus('r1', 'review');
    await Future<void>.delayed(Duration.zero);

    receiptsRepo.all = [makeReceipt('scanned-1')]; // бэкенд теперь содержит чек
    await n.confirm(); // → ScanSaved; должно инвалидировать список

    final after = await c.read(receiptsListControllerProvider.future);
    expect(after.items.map((r) => r.id), contains('scanned-1'));
  });

  test('recognizePhoto передаёт байты фото и QR в репозиторий', () async {
    final repo = FakeScanRepository();
    final c = _c(repo: repo, qr: FakeQrScanner(result: 'УИ'));
    await c
        .read(scanControllerProvider.notifier)
        .recognizePhoto(kValidPngBytes);
    expect(repo.receivedPhotoBytes, same(kValidPngBytes));
    expect(repo.receivedQr, 'УИ');
  });
}
