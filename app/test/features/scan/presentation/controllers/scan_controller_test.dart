import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/presentation/controllers/scan_controller.dart';

import '../../scan_test_fakes.dart';

ProviderContainer _container(
    {FakePhotoPicker? picker, FakeScanRepository? repo}) {
  final c = ProviderContainer(overrides: [
    photoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker()),
    scanRepositoryProvider.overrideWithValue(repo ?? FakeScanRepository()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('начальное состояние — ScanIdle', () {
    final c = _container();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });

  test('pickFromCamera с фото → ScanPreview', () async {
    final c = _container(picker: FakePhotoPicker()..result = kValidPngBytes);
    await c.read(scanControllerProvider.notifier).pickFromCamera();
    expect(c.read(scanControllerProvider), isA<ScanPreview>());
  });

  test('отмена выбора (null) → остаётся ScanIdle', () async {
    final c = _container(picker: FakePhotoPicker());
    await c.read(scanControllerProvider.notifier).pickFromGallery();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });

  test('отказ доступа к камере → ScanError(CameraPermissionDeniedFailure)',
      () async {
    final picker = FakePhotoPicker()
      ..error = PlatformException(code: 'camera_access_denied');
    final c = _container(picker: picker);
    await c.read(scanControllerProvider.notifier).pickFromCamera();
    final state = c.read(scanControllerProvider);
    expect(state, isA<ScanError>());
    expect((state as ScanError).failure, isA<CameraPermissionDeniedFailure>());
  });

  test('submit из превью → ScanSuccess с id', () async {
    final c = _container(
      picker: FakePhotoPicker()..result = kValidPngBytes,
      repo: FakeScanRepository()..receiptId = 'rid-7',
    );
    final notifier = c.read(scanControllerProvider.notifier);
    await notifier.pickFromCamera();
    await notifier.submit();
    final state = c.read(scanControllerProvider);
    expect(state, isA<ScanSuccess>());
    expect((state as ScanSuccess).receiptId, 'rid-7');
  });

  test('ошибка submit → ScanError с сохранёнными байтами', () async {
    final c = _container(
      picker: FakePhotoPicker()..result = kValidPngBytes,
      repo: FakeScanRepository()..error = const UploadFailure(),
    );
    final notifier = c.read(scanControllerProvider.notifier);
    await notifier.pickFromCamera();
    await notifier.submit();
    final state = c.read(scanControllerProvider);
    expect(state, isA<ScanError>());
    expect((state as ScanError).photoBytes, isNotNull);
  });

  test('retake → ScanIdle', () async {
    final c = _container(picker: FakePhotoPicker()..result = kValidPngBytes);
    final notifier = c.read(scanControllerProvider.notifier);
    await notifier.pickFromCamera();
    notifier.retake();
    expect(c.read(scanControllerProvider), isA<ScanIdle>());
  });
}
