import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/receipt_parser_impl.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/data/vision_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipts_list_controller.dart';
import 'package:ticket_app/features/scan/presentation/controllers/scan_controller.dart';

import '../../../receipts/receipts_test_fakes.dart';
import '../../prostore_ocr_fixture.dart';
import '../../scan_test_fakes.dart';

ProviderContainer _c({
  FakePhotoPicker? picker,
  FakeOcrEngine? engine,
  FakeScanRepository? repo,
}) {
  final c = ProviderContainer(overrides: [
    photoPickerProvider.overrideWithValue(
        picker ?? (FakePhotoPicker()..result = kValidPngBytes)),
    receiptOcrEngineProvider.overrideWithValue(engine ??
        FakeOcrEngine(const OcrResult(lines: prostoreOcrLines, qr: 'УИ'))),
    receiptParserProvider.overrideWithValue(ReceiptParserImpl()),
    scanRepositoryProvider.overrideWithValue(repo ?? FakeScanRepository()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('начальное состояние — ScanIdle', () {
    expect(_c().read(scanControllerProvider), isA<ScanIdle>());
  });

  test('recognizePhoto → ScanReview с 14 позициями', () async {
    final c = _c();
    await c
        .read(scanControllerProvider.notifier)
        .recognizePhoto(kValidPngBytes);
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanReview>());
    expect((s as ScanReview).draft.items.length, 14);
  });

  test('ошибка движка OCR → ScanError', () async {
    final c = _c(
      engine:
          FakeOcrEngine(const OcrResult(lines: []), error: Exception('boom')),
    );
    await c
        .read(scanControllerProvider.notifier)
        .recognizePhoto(kValidPngBytes);
    expect(c.read(scanControllerProvider), isA<ScanError>());
  });

  test('pickFromGallery с фото → ScanReview', () async {
    final c = _c(picker: FakePhotoPicker()..result = kValidPngBytes);
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanReview>());
  });

  test('отмена выбора (null) → остаётся ScanIdle', () async {
    final c = _c(picker: FakePhotoPicker());
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });

  test('removeItem убирает позицию из ревью', () async {
    final c = _c();
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes);
    n.removeItem(0);
    expect(
        (c.read(scanControllerProvider) as ScanReview).draft.items.length, 13);
  });

  test('save → ScanSaved с id', () async {
    final c = _c(repo: FakeScanRepository()..receiptId = 'rid-5');
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes);
    await n.save();
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanSaved>());
    expect((s as ScanSaved).receiptId, 'rid-5');
  });

  test('ошибка сохранения → ScanError с draft', () async {
    final c = _c(repo: FakeScanRepository()..error = const UploadFailure());
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes);
    await n.save();
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanError>());
    expect((s as ScanError).draft, isNotNull);
  });

  test('save() инвалидирует список чеков → новый чек виден без ручного refresh',
      () async {
    final receiptsRepo = FakeReceiptsRepository([]);
    final c = ProviderContainer(overrides: [
      photoPickerProvider
          .overrideWithValue(FakePhotoPicker()..result = kValidPngBytes),
      receiptOcrEngineProvider.overrideWithValue(
          FakeOcrEngine(const OcrResult(lines: prostoreOcrLines, qr: 'УИ'))),
      receiptParserProvider.overrideWithValue(ReceiptParserImpl()),
      scanRepositoryProvider.overrideWithValue(FakeScanRepository()),
      receiptsRepositoryProvider.overrideWithValue(receiptsRepo),
    ]);
    addTearDown(c.dispose);
    // Держим список «живым» — иначе autoDispose сам перезапросит данные при
    // повторном чтении, и тест прошёл бы даже без инвалидации (ложный успех).
    final sub = c.listen(receiptsListControllerProvider, (_, __) {});
    addTearDown(sub.close);

    final initial = await c.read(receiptsListControllerProvider.future);
    expect(initial.items, isEmpty);

    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes); // → ScanReview
    receiptsRepo.all = [makeReceipt('scanned-1')]; // бэкенд теперь содержит чек
    await n.save(); // → ScanSaved; должно инвалидировать список

    final after = await c.read(receiptsListControllerProvider.future);
    expect(after.items.map((r) => r.id), contains('scanned-1'));
  });
}
