/// Назначение: контроллер async-скана — фото → processing → realtime → ревью → confirm.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: dart:async, dart:typed_data, riverpod_annotation,
///   core/error/failure.dart, core/realtime/receipt_realtime.dart,
///   receipts/domain/entities/receipt_status.dart,
///   receipts/presentation/controllers/receipts_list_controller.dart,
///   data/photo_picker.dart, data/qr_scanner.dart,
///   data/repositories/scan_repository_impl.dart, data/scan_error_mapper.dart,
///   domain/entities/scanned_item.dart.
/// Ключевые типы: ScanState, ScanController, scanControllerProvider.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/realtime/receipt_realtime.dart';
import '../../../receipts/domain/entities/receipt_status.dart';
import '../../../receipts/presentation/controllers/receipts_list_controller.dart';
import '../../data/photo_picker.dart';
import '../../data/qr_scanner.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../data/scan_error_mapper.dart';
import '../../domain/entities/scanned_item.dart';

part 'scan_controller.g.dart';

/// Состояние экрана скана.
sealed class ScanState {
  const ScanState();
}

/// Исходное состояние: ожидание захвата фото.
class ScanIdle extends ScanState {
  const ScanIdle();
}

/// Загрузка фото и создание processing-чека.
class ScanUploading extends ScanState {
  const ScanUploading();
}

/// Чек создан, ожидаем результат серверного OCR (Realtime).
class ScanProcessing extends ScanState {
  const ScanProcessing(this.receiptId);
  final String receiptId;
}

/// Серверные позиции готовы — экран ревью.
class ScanReview extends ScanState {
  const ScanReview(this.receiptId, this.items);
  final String receiptId;
  final List<ScannedItem> items;
}

/// Подтверждение чека (RPC confirm_receipt).
class ScanConfirming extends ScanState {
  const ScanConfirming(this.receiptId, this.items);
  final String receiptId;
  final List<ScannedItem> items;
}

/// Чек подтверждён и сохранён.
class ScanSaved extends ScanState {
  const ScanSaved(this.receiptId);
  final String receiptId;
}

/// Ошибка любого этапа скана.
class ScanError extends ScanState {
  const ScanError(this.failure);
  final ScanFailure failure;
}

/// Управляет потоком: фото → upload+insert processing → Realtime → ревью → confirm.
@riverpod
class ScanController extends _$ScanController {
  StreamSubscription<List<Map<String, dynamic>>>? _receiptSub;

  @override
  ScanState build() {
    ref.onDispose(() => _receiptSub?.cancel());
    return const ScanIdle();
  }

  /// Снимок (камера/галерея) → upload + insert processing → ожидание воркера.
  Future<void> recognizePhoto(Uint8List bytes) async {
    state = const ScanUploading();
    try {
      final qr = await ref.read(qrScannerProvider).scan(bytes);
      final id = await ref
          .read(scanRepositoryProvider)
          .startScan(photoBytes: bytes, qrRaw: qr);
      state = ScanProcessing(id);
      _subscribe(id);
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

  void _subscribe(String receiptId) {
    _receiptSub?.cancel();
    _receiptSub = ref
        .read(receiptRealtimeProvider)
        .watchReceipt(receiptId)
        .listen((rows) async {
      if (rows.isEmpty) return;
      final status = ReceiptStatus.fromDb(rows.first['status'] as String?);
      if (status == ReceiptStatus.review) {
        await _loadReviewItems(receiptId);
      } else if (status == ReceiptStatus.failed) {
        final err = rows.first['error'] as String?;
        state =
            ScanError(UnknownScanFailure(err ?? 'Не удалось распознать чек'));
      }
    });
  }

  Future<void> _loadReviewItems(String receiptId) async {
    final rows =
        await ref.read(receiptRealtimeProvider).watchItems(receiptId).first;
    final items = rows.map(_itemFromRow).toList();
    state = ScanReview(receiptId, items);
  }

  ScannedItem _itemFromRow(Map<String, dynamic> r) => ScannedItem(
        rawName: r['raw_name'] as String? ?? '',
        qty: (r['qty'] as num?)?.toDouble() ?? 1,
        unitPrice: (r['unit_price'] as num?)?.toDouble() ?? 0,
        sum: (r['sum'] as num?)?.toDouble() ?? 0,
        confidence: (r['confidence'] as num?)?.toDouble(),
      );

  /// Удалить позицию из текущего ревью.
  void removeItem(int index) {
    final s = state;
    if (s is ScanReview) {
      state = ScanReview(s.receiptId, [...s.items]..removeAt(index));
    }
  }

  /// Подтвердить распознанный чек (confirm_receipt).
  Future<void> confirm() async {
    final s = state;
    if (s is! ScanReview) return;
    state = ScanConfirming(s.receiptId, s.items);
    try {
      await ref.read(scanRepositoryProvider).confirm(
        s.receiptId,
        [for (final it in s.items) it.toConfirmJson()],
      );
      state = ScanSaved(s.receiptId);
      // Список чеков кэшируется (экран жив в IndexedStack) — инвалидируем,
      // иначе подтверждённый чек не появится без ручного refresh.
      ref.invalidate(receiptsListControllerProvider);
    } catch (e) {
      state = ScanError(mapScanException(e));
    }
  }

  /// Сброс к началу.
  void reset() {
    _receiptSub?.cancel();
    _receiptSub = null;
    state = const ScanIdle();
  }
}
