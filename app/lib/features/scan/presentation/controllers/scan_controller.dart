/// Назначение: контроллер сканирования — состояние захвата/превью/отправки.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: dart:typed_data, riverpod_annotation, core/error/failure.dart,
///   data/photo_picker.dart, data/repositories/scan_repository_impl.dart,
///   data/scan_error_mapper.dart, domain/usecases/create_receipt_from_photo.dart.
/// Ключевые типы: ScanState, ScanController, scanControllerProvider.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../data/photo_picker.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../data/scan_error_mapper.dart';
import '../../domain/usecases/create_receipt_from_photo.dart';

part 'scan_controller.g.dart';

/// Состояние экрана сканирования.
sealed class ScanState {
  const ScanState();
}

/// Ничего не выбрано — показываем кнопки захвата.
class ScanIdle extends ScanState {
  const ScanIdle();
}

/// Фото выбрано, ожидает подтверждения отправки.
class ScanPreview extends ScanState {
  const ScanPreview(this.photoBytes);
  final Uint8List photoBytes;
}

/// Идёт загрузка и создание чека.
class ScanSubmitting extends ScanState {
  const ScanSubmitting(this.photoBytes);
  final Uint8List photoBytes;
}

/// Чек создан.
class ScanSuccess extends ScanState {
  const ScanSuccess(this.receiptId);
  final String receiptId;
}

/// Ошибка. [photoBytes] != null — ошибка отправки (можно повторить из превью);
/// null — ошибка выбора (возврат к экрану захвата).
class ScanError extends ScanState {
  const ScanError(this.failure, [this.photoBytes]);
  final ScanFailure failure;
  final Uint8List? photoBytes;
}

/// Управляет процессом сканирования чека.
@riverpod
class ScanController extends _$ScanController {
  @override
  ScanState build() => const ScanIdle();

  Future<void> pickFromCamera() => _pick((p) => p.pickFromCamera());
  Future<void> pickFromGallery() => _pick((p) => p.pickFromGallery());

  Future<void> _pick(Future<Uint8List?> Function(PhotoPicker) run) async {
    try {
      final bytes = await run(ref.read(photoPickerProvider));
      if (bytes == null) return; // отмена — состояние не меняем
      state = ScanPreview(bytes);
    } catch (e) {
      state = ScanError(mapScanException(e));
    }
  }

  /// Сброс к экрану захвата.
  void retake() => state = const ScanIdle();

  /// Сброс после успеха (синоним retake — для читаемости вызова из success-вида).
  void reset() => state = const ScanIdle();

  /// Отправка текущего фото (из превью или из состояния ошибки отправки).
  Future<void> submit() async {
    final bytes = switch (state) {
      ScanPreview(:final photoBytes) => photoBytes,
      ScanError(:final photoBytes?) => photoBytes,
      _ => null,
    };
    if (bytes == null) return;

    state = ScanSubmitting(bytes);
    try {
      final usecase = CreateReceiptFromPhoto(ref.read(scanRepositoryProvider));
      state = ScanSuccess(await usecase(bytes));
    } catch (e) {
      state = ScanError(mapScanException(e), bytes);
    }
  }
}
