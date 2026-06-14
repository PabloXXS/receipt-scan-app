/// Назначение: контроллер OCR-скана — захват фото → распознавание → ревью → сохранение.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: riverpod_annotation, core/error/failure.dart, data/photo_picker.dart,
///   data/vision_ocr_engine.dart, data/receipt_parser_impl.dart,
///   data/repositories/scan_repository_impl.dart, data/scan_error_mapper.dart,
///   domain/entities/receipt_draft.dart, domain/ocr/receipt_parser.dart,
///   domain/usecases/save_scanned_receipt.dart.
/// Ключевые типы: ScanState, ScanController, scanControllerProvider, receiptParserProvider.
library;

import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../data/photo_picker.dart';
import '../../data/receipt_parser_impl.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../data/scan_error_mapper.dart';
import '../../data/vision_ocr_engine.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/ocr/receipt_parser.dart';
import '../../domain/usecases/save_scanned_receipt.dart';

part 'scan_controller.g.dart';

/// Состояние экрана скана.
sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanRecognizing extends ScanState {
  const ScanRecognizing();
}

class ScanReview extends ScanState {
  const ScanReview(this.draft);
  final ReceiptDraft draft;
}

class ScanSaving extends ScanState {
  const ScanSaving(this.draft);
  final ReceiptDraft draft;
}

class ScanSaved extends ScanState {
  const ScanSaved(this.receiptId);
  final String receiptId;
}

class ScanError extends ScanState {
  const ScanError(this.failure, [this.draft]);
  final ScanFailure failure;
  final ReceiptDraft? draft;
}

/// DI-провайдер парсера.
final receiptParserProvider =
    Provider<ReceiptParser>((ref) => ReceiptParserImpl());

/// Управляет потоком: захват → OCR → парсинг → ревью → сохранение.
@riverpod
class ScanController extends _$ScanController {
  @override
  ScanState build() => const ScanIdle();

  /// Распознать готовый снимок (из живой камеры или галереи) → ревью.
  Future<void> recognizePhoto(Uint8List bytes) async {
    state = const ScanRecognizing();
    try {
      final ocr = await ref.read(receiptOcrEngineProvider).recognize(bytes);
      state = ScanReview(ref.read(receiptParserProvider).parse(ocr));
    } catch (e) {
      state = ScanError(mapScanException(e));
    }
  }

  /// Выбрать фото из галереи и распознать.
  Future<void> pickFromGallery() async {
    Uint8List? bytes;
    try {
      bytes = await ref.read(photoPickerProvider).pickFromGallery();
    } catch (e) {
      state = ScanError(mapScanException(e));
      return;
    }
    if (bytes == null) return; // отмена
    await recognizePhoto(bytes);
  }

  /// Удалить ошибочную позицию из текущего ревью.
  void removeItem(int index) {
    final s = state;
    if (s is ScanReview) state = ScanReview(s.draft.removeItemAt(index));
  }

  /// Сохранить распознанный чек.
  Future<void> save() async {
    final s = state;
    final draft = switch (s) {
      ScanReview(:final draft) => draft,
      ScanError(:final draft?) => draft,
      _ => null,
    };
    if (draft == null) return;
    state = ScanSaving(draft);
    try {
      final id =
          await SaveScannedReceipt(ref.read(scanRepositoryProvider))(draft);
      state = ScanSaved(id);
    } catch (e) {
      state = ScanError(mapScanException(e), draft);
    }
  }

  /// Сброс к началу.
  void reset() => state = const ScanIdle();
}
