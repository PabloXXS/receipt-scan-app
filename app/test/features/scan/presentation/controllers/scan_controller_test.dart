import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/receipt_parser_impl.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/data/vision_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/presentation/controllers/scan_controller.dart';

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

  test('pickFromCamera → распознавание → ScanReview с 14 позициями', () async {
    final c = _c();
    await c.read(scanControllerProvider.notifier).pickFromCamera();
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanReview>());
    expect((s as ScanReview).draft.items.length, 14);
  });

  test('отмена выбора (null) → остаётся ScanIdle', () async {
    final c = _c(picker: FakePhotoPicker());
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });

  test('removeItem убирает позицию из ревью', () async {
    final c = _c();
    final n = c.read(scanControllerProvider.notifier);
    await n.pickFromCamera();
    n.removeItem(0);
    expect(
        (c.read(scanControllerProvider) as ScanReview).draft.items.length, 13);
  });

  test('save → ScanSaved с id', () async {
    final c = _c(repo: FakeScanRepository()..receiptId = 'rid-5');
    final n = c.read(scanControllerProvider.notifier);
    await n.pickFromCamera();
    await n.save();
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanSaved>());
    expect((s as ScanSaved).receiptId, 'rid-5');
  });

  test('ошибка сохранения → ScanError с сохранённым draft', () async {
    final c = _c(repo: FakeScanRepository()..error = const UploadFailure());
    final n = c.read(scanControllerProvider.notifier);
    await n.pickFromCamera();
    await n.save();
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanError>());
    expect((s as ScanError).draft, isNotNull);
  });
}
