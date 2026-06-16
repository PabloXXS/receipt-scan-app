# Клиент Flutter: async-скан через серверный OCR — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перевести клиентский скан с синхронного OCR-на-устройстве на async-поток через серверный OCR: фото → `INSERT receipts(status=processing)` → Realtime-ожидание → экран-ревью серверных позиций с подсветкой `confidence` → подтверждение через RPC `confirm_receipt`. Удалить on-device OCR (Apple Vision text + Dart-парсер), сохранив только QR-детект.

**Architecture:** `ScanController` (Riverpod AsyncNotifier-стиль, sealed-состояния) управляет потоком; `core/realtime/` даёт supabase-stream подписку на строку `receipts` и `receipt_items`; подтверждение — `confirm_receipt` RPC. iOS-Vision обрезается до QR-only (`VNDetectBarcodesRequest`, канал `scan/qr`). Это план №4 (последний) из 4.

**Tech Stack:** Flutter, Riverpod (codegen), Supabase Realtime (`.stream()`), GoRouter, дизайн-система каталога (`shared/components`). Локально проверяется: `dart analyze`, `flutter test`.

**Верификация:** прогоняется ЛОКАЛЬНО — `cd app && flutter pub get && dart run build_runner build --delete-conflicting-outputs && dart analyze && flutter test`. Realtime тестируется на фейковых стримах (без реального Supabase). UI-ревью — субагент `flutter-design-reviewer`.

**Зависимости от предыдущих планов:** план №1 (OCR-сервис), №2 (статус `review` + `confirm_receipt`), №3 (воркер пишет позиции с confidence). Эта часть включает клиента в уже работающий серверный конвейер.

---

## Решения по объёму (зафиксированы)

- **QR/УИ:** сохраняем on-device QR-детект, обрезав Swift-код до `VNDetectBarcodesRequest` (канал `scan/qr` → `{qr}`). Текст-OCR (`VNRecognizeTextRequest`) и сортировка строк удаляются. `mobile_scanner` не вводим ([ios-simulator-run]).
- **Редактирование позиций в ревью:** на этом этапе — удаление строки (как сейчас) + подтверждение. Полноценное редактирование полей — отдельный follow-up (как и было отложено в scan.md).
- **Удаляем:** `VisionOcrEngine`, `ReceiptParserImpl`, `ReceiptParser`, `OcrResult`, `ReceiptOcrEngine`, `SaveScannedReceipt`, `insertReceiptWithItems`, on-device текст-OCR. Их тесты/фикстуры — тоже.

---

## Файлы

- Modify: `app/lib/features/receipts/domain/entities/receipt_status.dart` — значение `review`.
- Modify: `app/lib/features/receipts/domain/entities/receipt_item.dart` — поле `confidence`.
- Modify: `app/lib/features/receipts/data/models/receipt_dto.dart` — маппинг `confidence` + колонка.
- Create: `app/lib/core/realtime/receipt_realtime.dart` — стримы статуса чека и позиций.
- Modify: `app/lib/features/scan/data/datasources/scan_remote_datasource.dart` — `insertProcessingReceipt`, `confirmReceipt`; удалить `insertReceiptWithItems`.
- Modify: `app/lib/features/scan/domain/repositories/scan_repository.dart` — новый контракт.
- Modify: `app/lib/features/scan/data/repositories/scan_repository_impl.dart` — реализация.
- Modify: `app/lib/features/scan/presentation/controllers/scan_controller.dart` — новый стейт-машина.
- Modify: `app/lib/features/scan/presentation/widgets/receipt_review_view.dart` — серверные позиции + confidence.
- Modify: `app/lib/features/scan/presentation/screens/scan_screen.dart` — новые состояния.
- Create: `app/lib/features/scan/domain/entities/scanned_item.dart` — редактируемая позиция ревью (с confidence).
- Modify: `app/ios/Runner/AppDelegate.swift` — QR-only.
- Modify: `app/lib/features/scan/data/vision_ocr_engine.dart` → заменить на `qr_scanner.dart` (QR-only) ИЛИ удалить и создать новый.
- Delete: `receipt_parser_impl.dart`, `domain/ocr/receipt_parser.dart`, `domain/ocr/receipt_ocr_engine.dart`, `domain/entities/ocr_result.dart`, `domain/usecases/save_scanned_receipt.dart` + их тесты/фикстуры.
- Modify: `docs/features/scan.md` — «Реализовано» обновить.

---

### Task 1: Доменные модели — статус `review` и `confidence` на позиции

**Files:**
- Modify: `app/lib/features/receipts/domain/entities/receipt_status.dart`
- Modify: `app/lib/features/receipts/domain/entities/receipt_item.dart`
- Modify: `app/lib/features/receipts/data/models/receipt_dto.dart`
- Test: `app/test/features/receipts/domain/receipt_status_test.dart` (создать/дополнить)

- [ ] **Step 1: Тест на статус review**

`app/test/features/receipts/domain/receipt_status_test.dart`:
```dart
import 'package:chekiprices/features/receipts/domain/entities/receipt_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromDb maps review', () {
    expect(ReceiptStatus.fromDb('review'), ReceiptStatus.review);
    expect(ReceiptStatus.fromDb('processing'), ReceiptStatus.processing);
    expect(ReceiptStatus.fromDb('done'), ReceiptStatus.done);
    expect(ReceiptStatus.fromDb('failed'), ReceiptStatus.failed);
    expect(ReceiptStatus.fromDb('unknown'), ReceiptStatus.pending);
  });
}
```

> Имя пакета (`chekiprices`) сверь с `app/pubspec.yaml` (`name:`) — используй фактическое во всех импортах тестов.

- [ ] **Step 2: Запустить тест — упадёт**

Run: `cd app && flutter test test/features/receipts/domain/receipt_status_test.dart`
Expected: FAIL — нет `ReceiptStatus.review`.

- [ ] **Step 3: Добавить review в enum**

В `receipt_status.dart` добавить значение между `processing` и `done`:
```dart
  /// Ожидает подтверждения пользователем после распознавания.
  review('На проверку'),
```
и в `fromDb` ветку `'review' => ReceiptStatus.review,`.

- [ ] **Step 4: confidence в ReceiptItem**

В `receipt_item.dart` добавить поле:
```dart
  const ReceiptItem({
    required this.id,
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
    this.confidence,
  });
  ...
  final double? confidence;
```

- [ ] **Step 5: Маппинг confidence в receipt_dto.dart**

Прочитать `receipt_dto.dart`. В `kReceiptItemColumns` добавить `confidence`. В `receiptItemFromRow` мапить:
```dart
    confidence: (row['confidence'] as num?)?.toDouble(),
```

- [ ] **Step 6: Запустить тест — пройдёт**

Run: `cd app && flutter test test/features/receipts/domain/receipt_status_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/pablo/work/receipt-scan-app
git add app/lib/features/receipts/domain/entities/receipt_status.dart app/lib/features/receipts/domain/entities/receipt_item.dart app/lib/features/receipts/data/models/receipt_dto.dart app/test/features/receipts/domain/receipt_status_test.dart
git commit -m "feat(receipts): review status and item confidence"
```

---

### Task 2: Редактируемая позиция ревью — ScannedItem

**Files:**
- Create: `app/lib/features/scan/domain/entities/scanned_item.dart`
- Test: `app/test/features/scan/domain/scanned_item_test.dart`

Позиция, доставленная воркером и редактируемая в ревью. Несёт confidence для подсветки.

- [ ] **Step 1: Тест**

`app/test/features/scan/domain/scanned_item_test.dart`:
```dart
import 'package:chekiprices/features/scan/domain/entities/scanned_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lowConfidence threshold', () {
    expect(const ScannedItem(rawName: 'A', qty: 1, unitPrice: 1, sum: 1, confidence: 0.5).lowConfidence, isTrue);
    expect(const ScannedItem(rawName: 'A', qty: 1, unitPrice: 1, sum: 1, confidence: 0.9).lowConfidence, isFalse);
    expect(const ScannedItem(rawName: 'A', qty: 1, unitPrice: 1, sum: 1).lowConfidence, isFalse);
  });

  test('toJson shape for confirm_receipt', () {
    const i = ScannedItem(rawName: 'Молоко', qty: 2, unitPrice: 1.25, sum: 2.5, confidence: 0.8);
    expect(i.toConfirmJson(), {
      'raw_name': 'Молоко', 'qty': 2.0, 'unit_price': 1.25, 'sum': 2.5,
    });
  });
}
```

- [ ] **Step 2: Запустить — упадёт.** `cd app && flutter test test/features/scan/domain/scanned_item_test.dart` → FAIL.

- [ ] **Step 3: Реализация**

`app/lib/features/scan/domain/entities/scanned_item.dart`:
```dart
/// Назначение: распознанная воркером позиция чека для экрана ревью.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: ScannedItem.
library;

/// Позиция, доставленная сервером (receipt_items), редактируемая в ревью.
class ScannedItem {
  const ScannedItem({
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
    this.confidence,
  });

  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;
  final double? confidence;

  /// Порог подсветки сомнительных позиций в ревью.
  static const double kLowConfidence = 0.7;

  /// Уверенность ниже порога (подсветить в ревью).
  bool get lowConfidence => confidence != null && confidence! < kLowConfidence;

  /// Полезная нагрузка позиции для RPC confirm_receipt.
  Map<String, dynamic> toConfirmJson() => {
        'raw_name': rawName,
        'qty': qty,
        'unit_price': unitPrice,
        'sum': sum,
      };
}
```

- [ ] **Step 4: Запустить — пройдёт.** PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/domain/entities/scanned_item.dart app/test/features/scan/domain/scanned_item_test.dart
git commit -m "feat(scan): ScannedItem entity with confidence and confirm payload"
```

---

### Task 3: Realtime — стрим статуса чека и позиций

**Files:**
- Create: `app/lib/core/realtime/receipt_realtime.dart`
- Test: `app/test/core/realtime/receipt_realtime_test.dart`

Тонкая обёртка над supabase `.stream()`. Тестируется на инъектируемой абстракции, без реального Supabase.

- [ ] **Step 1: Реализация (абстракция + Supabase-реализация)**

`app/lib/core/realtime/receipt_realtime.dart`:
```dart
/// Назначение: Realtime-подписки на строку чека и его позиции.
///
/// Слой: core/infra
/// Зависимости: flutter_riverpod, supabase_flutter, core/supabase/supabase_providers.dart.
/// Ключевые типы: ReceiptRealtime, receiptRealtimeProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';

/// Поток обновлений строки `receipts` и её `receipt_items`.
abstract interface class ReceiptRealtime {
  /// Стрим строк `receipts` по id (одна строка или пусто).
  Stream<List<Map<String, dynamic>>> watchReceipt(String id);

  /// Стрим позиций `receipt_items` по receipt_id.
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId);
}

/// Реализация поверх Supabase Realtime (`.stream()`).
class SupabaseReceiptRealtime implements ReceiptRealtime {
  const SupabaseReceiptRealtime(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) => _client
      .from('receipts')
      .stream(primaryKey: ['id']).eq('id', id);

  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) => _client
      .from('receipt_items')
      .stream(primaryKey: ['id']).eq('receipt_id', receiptId);
}

/// DI-провайдер Realtime-сервиса чеков.
final receiptRealtimeProvider = Provider<ReceiptRealtime>(
  (ref) => SupabaseReceiptRealtime(ref.watch(supabaseClientProvider)),
);
```

> Прочитай `app/lib/core/supabase/supabase_providers.dart` — убедись в имени `supabaseClientProvider`; если отличается, используй фактическое.

- [ ] **Step 2: Тест — мапперы статуса/позиций из строк**

Realtime сам по себе (Supabase) не юнит-тестируется без сети; тестируем чистые мапперы в контроллере (Task 5). Здесь — только smoke на интерфейс через фейк:

`app/test/core/realtime/receipt_realtime_test.dart`:
```dart
import 'package:chekiprices/core/realtime/receipt_realtime.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRealtime implements ReceiptRealtime {
  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) =>
      Stream.value([{'id': id, 'status': 'review'}]);
  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) =>
      Stream.value([]);
}

void main() {
  test('fake realtime emits receipt row', () async {
    final r = await _FakeRealtime().watchReceipt('r1').first;
    expect(r.single['status'], 'review');
  });
}
```

- [ ] **Step 3: Запустить тесты — пройдут.** `cd app && flutter test test/core/realtime/` → PASS.

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/realtime/receipt_realtime.dart app/test/core/realtime/receipt_realtime_test.dart
git commit -m "feat(realtime): receipt row and items streams"
```

---

### Task 4: Datasource/repository — insertProcessingReceipt + confirmReceipt

**Files:**
- Modify: `app/lib/features/scan/data/datasources/scan_remote_datasource.dart`
- Modify: `app/lib/features/scan/domain/repositories/scan_repository.dart`
- Modify: `app/lib/features/scan/data/repositories/scan_repository_impl.dart`
- Test: `app/test/features/scan/data/scan_remote_datasource_test.dart` (если возможен мок) — иначе репозиторий через фейковый datasource.

- [ ] **Step 1: Новый контракт datasource**

В `scan_remote_datasource.dart`: оставить `uploadPhoto`; заменить `insertReceiptWithItems` на:
```dart
  /// Создаёт «сырой» чек в статусе processing. Возвращает id чека.
  Future<String> insertProcessingReceipt({String? photoPath, String? qrRaw});

  /// Подтверждает чек после ревью через RPC confirm_receipt.
  Future<void> confirmReceipt(String receiptId, List<Map<String, dynamic>> items);
```
Реализация в `SupabaseScanRemoteDataSource`:
```dart
  @override
  Future<String> insertProcessingReceipt({String? photoPath, String? qrRaw}) async {
    final receipt = await _client
        .from('receipts')
        .insert({
          'source': ScanSource.ocr.dbValue,
          'qr_raw': qrRaw,
          'status': 'processing',
          'photo_path': photoPath,
        })
        .select('id')
        .single();
    return receipt['id'] as String;
  }

  @override
  Future<void> confirmReceipt(String receiptId, List<Map<String, dynamic>> items) async {
    await _client.rpc('confirm_receipt', params: {
      'p_receipt_id': receiptId,
      'p_items': items,
    });
  }
```
Удалить метод `insertReceiptWithItems` и его реализацию.

- [ ] **Step 2: Контракт repository**

В `scan_repository.dart` заменить `saveScannedReceipt` на:
```dart
  /// Загружает фото (best-effort) и создаёт чек в processing. Возвращает id.
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw});

  /// Подтверждает распознанный чек после ревью.
  Future<void> confirm(String receiptId, List<Map<String, dynamic>> items);
```

- [ ] **Step 3: Реализация repository**

В `scan_repository_impl.dart`:
```dart
  @override
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw}) async {
    try {
      String? photoPath;
      if (photoBytes != null) {
        try {
          final jpeg = processReceiptPhoto(photoBytes);
          photoPath = await _ds.uploadPhoto(jpeg);
        } catch (_) {
          photoPath = null;
        }
      }
      return await _ds.insertProcessingReceipt(photoPath: photoPath, qrRaw: qrRaw);
    } catch (e) {
      throw mapScanException(e);
    }
  }

  @override
  Future<void> confirm(String receiptId, List<Map<String, dynamic>> items) async {
    try {
      await _ds.confirmReceipt(receiptId, items);
    } catch (e) {
      throw mapScanException(e);
    }
  }
```

- [ ] **Step 4: Тест репозитория через фейковый datasource**

`app/test/features/scan/data/scan_repository_impl_test.dart`:
```dart
import 'dart:typed_data';
import 'package:chekiprices/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:chekiprices/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDs implements ScanRemoteDataSource {
  String? uploadedFrom;
  String? insertedPhotoPath;
  List<Map<String, dynamic>>? confirmedItems;

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    uploadedFrom = 'up';
    return 'uid/ts.jpg';
  }
  @override
  Future<String> insertProcessingReceipt({String? photoPath, String? qrRaw}) async {
    insertedPhotoPath = photoPath;
    return 'r1';
  }
  @override
  Future<void> confirmReceipt(String id, List<Map<String, dynamic>> items) async {
    confirmedItems = items;
  }
}

void main() {
  test('startScan uploads photo then inserts processing receipt', () async {
    final ds = _FakeDs();
    final id = await ScanRepositoryImpl(ds).startScan(photoBytes: Uint8List(8));
    expect(id, 'r1');
    expect(ds.insertedPhotoPath, 'uid/ts.jpg');
  });

  test('confirm forwards items', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds).confirm('r1', [{'raw_name': 'A'}]);
    expect(ds.confirmedItems, [{'raw_name': 'A'}]);
  });
}
```

> `processReceiptPhoto` обрабатывает реальные байты — в тесте `Uint8List(8)` может бросить; тогда photoPath=null (best-effort), и `insertedPhotoPath` будет null. Если так — поправь ассерт первого теста на `isNull` и проверяй только `id == 'r1'`. Сначала убедись в поведении `processReceiptPhoto`, не подгоняй вслепую.

- [ ] **Step 5: Запустить — пройдёт.** `cd app && flutter test test/features/scan/data/scan_repository_impl_test.dart`.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/scan/data/datasources/scan_remote_datasource.dart app/lib/features/scan/domain/repositories/scan_repository.dart app/lib/features/scan/data/repositories/scan_repository_impl.dart app/test/features/scan/data/scan_repository_impl_test.dart
git commit -m "feat(scan): start-processing insert and confirm_receipt datasource/repo"
```

---

### Task 5: ScanController — async стейт-машина с Realtime

**Files:**
- Modify: `app/lib/features/scan/presentation/controllers/scan_controller.dart`
- Test: `app/test/features/scan/presentation/scan_controller_test.dart` (переписать)

Новые состояния: `ScanIdle`, `ScanUploading`, `ScanProcessing(receiptId)`, `ScanReview(receiptId, items)`, `ScanConfirming(receiptId, items)`, `ScanSaved(receiptId)`, `ScanError(failure)`. Поток: `recognizePhoto(bytes)` → upload+insert → `Processing` → подписка realtime → при `status=review` собрать позиции → `Review`; при `failed` → `Error`. `confirm()` → RPC → `Saved`.

- [ ] **Step 1: Переписать контроллер**

```dart
/// Назначение: контроллер async-скана — фото → processing → realtime → ревью → confirm.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: riverpod_annotation, core/error/failure.dart, core/realtime/receipt_realtime.dart,
///   data/repositories/scan_repository_impl.dart, data/photo_picker.dart, data/scan_error_mapper.dart,
///   data/qr_scanner.dart, domain/entities/scanned_item.dart,
///   receipts/domain/entities/receipt_status.dart.
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

sealed class ScanState {
  const ScanState();
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanUploading extends ScanState {
  const ScanUploading();
}

class ScanProcessing extends ScanState {
  const ScanProcessing(this.receiptId);
  final String receiptId;
}

class ScanReview extends ScanState {
  const ScanReview(this.receiptId, this.items);
  final String receiptId;
  final List<ScannedItem> items;
}

class ScanConfirming extends ScanState {
  const ScanConfirming(this.receiptId, this.items);
  final String receiptId;
  final List<ScannedItem> items;
}

class ScanSaved extends ScanState {
  const ScanSaved(this.receiptId);
  final String receiptId;
}

class ScanError extends ScanState {
  const ScanError(this.failure);
  final ScanFailure failure;
}

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
    if (bytes == null) return;
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
        state = ScanError(ScanFailure(err ?? 'Не удалось распознать чек'));
      }
    });
  }

  Future<void> _loadReviewItems(String receiptId) async {
    final rows = await ref.read(receiptRealtimeProvider).watchItems(receiptId).first;
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
```

> Проверь сигнатуру `ScanFailure` в `core/error/failure.dart` — конструктор с сообщением. Если `ScanFailure` создаётся иначе (например, фабрики), используй фактический способ; не выдумывай.

- [ ] **Step 2: build_runner**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: перегенерирован `scan_controller.g.dart` без ошибок.

- [ ] **Step 3: Переписать тест контроллера**

`app/test/features/scan/presentation/scan_controller_test.dart` — с фейками `ScanRepository`, `ReceiptRealtime`, `QrScanner`, `PhotoPicker` через override провайдеров. Проверить:
- `recognizePhoto` → `ScanUploading` → `ScanProcessing(id)`;
- эмиссия realtime-строки со `status=review` → `ScanReview` с позициями;
- `status=failed` → `ScanError`;
- `confirm()` → `ScanSaved`.

Полный тест (фейки + ProviderContainer):
```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:chekiprices/core/realtime/receipt_realtime.dart';
import 'package:chekiprices/features/scan/data/photo_picker.dart';
import 'package:chekiprices/features/scan/data/qr_scanner.dart';
import 'package:chekiprices/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:chekiprices/features/scan/domain/repositories/scan_repository.dart';
import 'package:chekiprices/features/scan/presentation/controllers/scan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements ScanRepository {
  List<Map<String, dynamic>>? confirmed;
  @override
  Future<String> startScan({Uint8List? photoBytes, String? qrRaw}) async => 'r1';
  @override
  Future<void> confirm(String id, List<Map<String, dynamic>> items) async {
    confirmed = items;
  }
}

class _FakeRealtime implements ReceiptRealtime {
  final _receipt = StreamController<List<Map<String, dynamic>>>.broadcast();
  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) => _receipt.stream;
  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) =>
      Stream.value([
        {'raw_name': 'Молоко', 'qty': 1, 'unit_price': 2.5, 'sum': 2.5, 'confidence': 0.9},
      ]);
}

class _FakeQr implements QrScanner {
  @override
  Future<String?> scan(Uint8List bytes) async => null;
}

void main() {
  test('photo -> uploading -> processing -> review -> saved', () async {
    final repo = _FakeRepo();
    final rt = _FakeRealtime();
    final container = ProviderContainer(overrides: [
      scanRepositoryProvider.overrideWithValue(repo),
      receiptRealtimeProvider.overrideWithValue(rt),
      qrScannerProvider.overrideWithValue(_FakeQr()),
    ]);
    addTearDown(container.dispose);

    final ctrl = container.read(scanControllerProvider.notifier);
    await ctrl.recognizePhoto(Uint8List(8));
    expect(container.read(scanControllerProvider), isA<ScanProcessing>());

    rt._receipt.add([{'id': 'r1', 'status': 'review'}]);
    await Future<void>.delayed(Duration.zero);
    final review = container.read(scanControllerProvider);
    expect(review, isA<ScanReview>());
    expect((review as ScanReview).items.single.rawName, 'Молоко');

    await ctrl.confirm();
    expect(container.read(scanControllerProvider), isA<ScanSaved>());
    expect(repo.confirmed!.single['raw_name'], 'Молоко');
  });
}
```

> `qrScannerProvider`/`QrScanner` создаются в Task 6. Если выполняешь Task 5 раньше — создай минимальный `qr_scanner.dart` стуб с интерфейсом до Task 6 ИЛИ переставь Task 6 перед Task 5. Рекомендуется: сделать Task 6 (QR) до Task 5.

- [ ] **Step 4: Запустить тест** — `cd app && flutter test test/features/scan/presentation/scan_controller_test.dart` → PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/presentation/controllers/scan_controller.dart app/lib/features/scan/presentation/controllers/scan_controller.g.dart app/test/features/scan/presentation/scan_controller_test.dart
git commit -m "feat(scan): async controller with realtime processing and confirm"
```

---

### Task 6: QR-only сканер (замена VisionOcrEngine) + обрезка Swift

**Files:**
- Create: `app/lib/features/scan/data/qr_scanner.dart`
- Delete: `app/lib/features/scan/data/vision_ocr_engine.dart`
- Modify: `app/ios/Runner/AppDelegate.swift`

> ВЫПОЛНИ ЭТУ ЗАДАЧУ ДО Task 5 (контроллер зависит от `qrScannerProvider`).

- [ ] **Step 1: qr_scanner.dart**

```dart
/// Назначение: извлечение QR (УИ) из фото чека через нативный канал scan/qr.
///
/// Слой: data
/// Фича: scan
/// Зависимости: flutter/services, flutter_riverpod, domain — нет.
/// Ключевые типы: QrScanner, VisionQrScanner, qrScannerProvider.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Извлекает строку QR из фото (или null).
abstract interface class QrScanner {
  Future<String?> scan(Uint8List photoBytes);
}

/// Реализация поверх нативного Vision (канал scan/qr).
class VisionQrScanner implements QrScanner {
  const VisionQrScanner();

  static const _channel = MethodChannel('scan/qr');

  @override
  Future<String?> scan(Uint8List photoBytes) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      'scanQr',
      {'bytes': photoBytes},
    );
    return res?['qr'] as String?;
  }
}

/// DI-провайдер QR-сканера.
final qrScannerProvider = Provider<QrScanner>((ref) => const VisionQrScanner());
```

- [ ] **Step 2: Обрезать Swift до QR-only**

В `app/ios/Runner/AppDelegate.swift` заменить `ReceiptOcr` на QR-only: канал `scan/qr`, метод `scanQr`, только `VNDetectBarcodesRequest`, удалить `VNRecognizeTextRequest` и сортировку строк. Регистрацию в `didFinishLaunchingWithOptions` обновить (`ReceiptOcr.register` → имя оставить или переименовать `ReceiptQr`). Возврат: `result(["qr": qr as Any])`.

```swift
// Распознавание QR (УИ) чека по байтам фото через Vision.
enum ReceiptQr {
  static func register(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "scan/qr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "scanQr",
            let args = call.arguments as? [String: Any],
            let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: data), let cg = image.cgImage else {
        result(FlutterError(code: "bad_args", message: "no image bytes", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        var qr: String?
        let qrReq = VNDetectBarcodesRequest { req, _ in
          for obs in (req.results as? [VNBarcodeObservation]) ?? []
          where obs.symbology == .qr {
            if let p = obs.payloadStringValue { qr = p; break }
          }
        }
        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([qrReq])
        DispatchQueue.main.async { result(["qr": qr as Any]) }
      }
    }
  }
}
```
И в `didFinishLaunchingWithOptions`: `ReceiptQr.register(controller.binaryMessenger)`.

- [ ] **Step 3: Удалить vision_ocr_engine.dart**

```bash
git rm app/lib/features/scan/data/vision_ocr_engine.dart
```

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/scan/data/qr_scanner.dart app/ios/Runner/AppDelegate.swift
git commit -m "feat(scan): QR-only native scanner, drop on-device text OCR engine"
```

---

### Task 7: Экран и ревью — серверные позиции + подсветка confidence

**Files:**
- Modify: `app/lib/features/scan/presentation/screens/scan_screen.dart`
- Modify: `app/lib/features/scan/presentation/widgets/receipt_review_view.dart`
- Test: `app/test/features/scan/presentation/screens/scan_screen_test.dart` (обновить)

- [ ] **Step 1: scan_screen.dart — новые состояния**

```dart
    final body = switch (state) {
      ScanIdle() => const ScanCaptureView(),
      ScanError() => ScanCaptureView(error: state.failure.message),
      ScanUploading() => const AppLoader(),
      ScanProcessing() => const _ProcessingView(),
      ScanReview(:final items) => ReceiptReviewView(items: items),
      ScanConfirming(:final items) => ReceiptReviewView(items: items, saving: true),
      ScanSaved() => const _SavedView(),
    };
```
Добавить `_ProcessingView` (через `AppLoader` + текст «Распознаём чек…», композиция каталога):
```dart
class _ProcessingView extends StatelessWidget {
  const _ProcessingView();
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(),
          SizedBox(height: tokens.spaceLg),
          Text('Распознаём чек…', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
```
`_SavedView` — оставить как есть (его кнопка вызывает `controller.reset`).

- [ ] **Step 2: receipt_review_view.dart — на ScannedItem + confidence**

Переписать на `List<ScannedItem> items`; итог = сумма позиций; подсветка `lowConfidence` через `AppBadge`/иконку у строки; кнопка «Подтвердить» → `controller.confirm`; «Отмена» → `controller.reset`.
```dart
class ReceiptReviewView extends ConsumerWidget {
  const ReceiptReviewView({super.key, required this.items, this.saving = false, this.error});

  final List<ScannedItem> items;
  final bool saving;
  final String? error;

  static const _currency = 'BYN';

  double get _sum => items.fold(0, (a, i) => a + i.sum);
  bool get _hasLowConfidence => items.any((i) => i.lowConfidence);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(scanControllerProvider.notifier);

    return Column(
      children: [
        if (_hasLowConfidence)
          Padding(
            padding: EdgeInsets.all(tokens.spaceMd),
            child: const AppBadge(
              label: 'Часть позиций распознана неуверенно — проверьте',
              tone: AppBadgeTone.warning,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return Dismissible(
                key: ValueKey('item_${i}_${it.rawName}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => controller.removeItem(i),
                background: ColoredBox(color: scheme.errorContainer),
                child: AppListTile(
                  leading: it.lowConfidence
                      ? Icon(Icons.help_outline, color: scheme.tertiary)
                      : null,
                  title: it.rawName,
                  subtitle: '${it.qty} × ${it.unitPrice}',
                  trailing: MoneyText(it.sum, currencyCode: _currency),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого', style: textTheme.titleMedium),
                  MoneyText(_sum, currencyCode: _currency),
                ],
              ),
              if (error != null) ...[
                SizedBox(height: tokens.spaceSm),
                Text(error!, textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error)),
              ],
              SizedBox(height: tokens.spaceLg),
              AppButton(
                label: 'Подтвердить',
                icon: Icons.check,
                expanded: true,
                loading: saving,
                onPressed: saving ? null : controller.confirm,
              ),
              SizedBox(height: tokens.spaceSm),
              AppButton(
                label: 'Отмена',
                variant: AppButtonVariant.text,
                expanded: true,
                onPressed: saving ? null : controller.reset,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```
Обнови dartdoc-шапку и импорты (убрать `receipt_draft`, добавить `scanned_item`). Проверь, что `AppListTile` поддерживает `leading` — если нет, подсветку дай иным разрешённым способом (например, `AppBadge` в subtitle); сверься с `shared/components`.

- [ ] **Step 3: Обновить scan_screen_test.dart** — под новые состояния (Idle/Processing/Review/Saved). Проверь, что экран рендерит `_ProcessingView` при `ScanProcessing` и `ReceiptReviewView` при `ScanReview` (через override контроллера или стартовое состояние).

- [ ] **Step 4: Запустить тесты** — `cd app && flutter test test/features/scan/` → PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/presentation/ app/test/features/scan/presentation/screens/scan_screen_test.dart
git commit -m "feat(scan): processing view and server-item review with confidence"
```

---

### Task 8: Удаление on-device OCR (Dart) + тестов/фикстур

**Files (delete):**
- `app/lib/features/scan/data/receipt_parser_impl.dart`
- `app/lib/features/scan/domain/ocr/receipt_parser.dart`
- `app/lib/features/scan/domain/ocr/receipt_ocr_engine.dart`
- `app/lib/features/scan/domain/entities/ocr_result.dart`
- `app/lib/features/scan/domain/usecases/save_scanned_receipt.dart`
- `app/test/features/scan/data/receipt_parser_impl_test.dart`
- `app/test/features/scan/data/receipt_parser_real_test.dart`
- `app/test/features/scan/prostore_ocr_fixture.dart`
- `app/test/features/scan/prostore_vision_real.dart`

- [ ] **Step 1: Удалить файлы**

```bash
cd /Users/pablo/work/receipt-scan-app
git rm app/lib/features/scan/data/receipt_parser_impl.dart \
  app/lib/features/scan/domain/ocr/receipt_parser.dart \
  app/lib/features/scan/domain/ocr/receipt_ocr_engine.dart \
  app/lib/features/scan/domain/entities/ocr_result.dart \
  app/lib/features/scan/domain/usecases/save_scanned_receipt.dart \
  app/test/features/scan/data/receipt_parser_impl_test.dart \
  app/test/features/scan/data/receipt_parser_real_test.dart \
  app/test/features/scan/prostore_ocr_fixture.dart \
  app/test/features/scan/prostore_vision_real.dart
```
Если какого-то файла нет — пропусти его в команде.

- [ ] **Step 2: Вычистить ссылки**

Grep на оставшиеся импорты удалённого: `receiptOcrEngineProvider`, `receiptParserProvider`, `ReceiptParser`, `OcrResult`, `ReceiptDraft`, `SaveScannedReceipt`, `receipt_draft`.
Run: `cd app && grep -rn "receiptOcrEngine\|receiptParserProvider\|ReceiptParser\|OcrResult\|SaveScannedReceipt\|receipt_draft\|vision_ocr_engine" lib test`
Удалить/поправить все вхождения (в т.ч. `scan_test_fakes.dart`, если ссылается). `ReceiptDraft` тоже удаляется — но сначала убедись, что он больше нигде не нужен; если используется только сканом — удали `receipt_draft.dart` и обнови grep.

- [ ] **Step 3: Анализ**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs && dart analyze`
Expected: без ошибок (нет битых импортов).

- [ ] **Step 4: Commit**

```bash
git add -A app/lib/features/scan app/test/features/scan
git commit -m "refactor(scan): remove on-device OCR text engine, parser and drafts"
```

---

### Task 9: Зелёная сборка + дизайн-ревью + документация

**Files:**
- Modify: `docs/features/scan.md`

- [ ] **Step 1: Полный прогон**

Run: `cd app && flutter pub get && dart run build_runner build --delete-conflicting-outputs && dart analyze && flutter test`
Expected: analyze без ошибок; все тесты PASS. Чинить найденное (битые импорты после удаления, изменённые сигнатуры).

- [ ] **Step 2: flutter-design-reviewer**

Запустить субагент `flutter-design-reviewer` на изменения в `lib/features/scan/presentation/` и `lib/core/realtime/`: токены вместо хардкода, компоненты каталога (AppBadge/AppListTile/AppButton/AppLoader/MoneyText), const-корректность, light/dark, доступность подсветки confidence (не только цвет — есть иконка). Исправить замечания.

- [ ] **Step 3: Обновить scan.md**

Раздел «Реализовано» и «Взаимодействие с воркером»: клиент теперь делает `INSERT receipts(status=processing)`, подписывается на Realtime, показывает экран-ревью серверных позиций с подсветкой confidence, подтверждает через `confirm_receipt`. iOS-Vision обрезан до QR-only (канал `scan/qr`). On-device текст-OCR/парсер удалены. Обновить разделы «Репозитории и use-cases», «Riverpod-провайдеры» (`scanControllerProvider`, `qrScannerProvider`, `receiptRealtimeProvider`, `photoPickerProvider`, `scanRepositoryProvider`; удалены `receiptOcrEngineProvider`, `receiptParserProvider`).

- [ ] **Step 4: Commit**

```bash
git add docs/features/scan.md
git commit -m "docs(scan): async server-OCR client flow"
```

---

## Self-Review (выполнено при написании плана)

- **Spec coverage:** «Компонент 4 — Клиент» из спеки: async-поток processing — Tasks 4–5;
  Realtime — Tasks 3, 5; экран-ревью + подсветка confidence — Tasks 2, 7; `confirm_receipt` —
  Tasks 4–5; удаление Vision/парсера — Tasks 6, 8; QR на устройстве сохранён (QR-only) —
  Task 6. Статус `review` на клиенте — Task 1.
- **Placeholder scan:** кода-плейсхолдеров нет. Несколько врезок требуют сверки с фактом
  (`ScanFailure` конструктор, `supabaseClientProvider`, `AppListTile.leading`, поведение
  `processReceiptPhoto`, имя пакета) — это явные инструкции «проверь и используй
  фактическое», не TODO.
- **Type/имя consistency:** `ScanState` (Idle/Uploading/Processing/Review/Confirming/Saved/
  Error), `ScannedItem(rawName,qty,unitPrice,sum,confidence)` + `toConfirmJson()` +
  `lowConfidence`, `ScanRepository.startScan/confirm`, `ScanRemoteDataSource.
  insertProcessingReceipt/confirmReceipt`, `ReceiptRealtime.watchReceipt/watchItems`,
  `QrScanner.scan`, `ReceiptStatus.review` — согласованы между задачами и тестами.
- **Порядок задач:** Task 6 (QR) ДО Task 5 (контроллер) — отмечено во врезке Task 5/6.

## Известные риски (для исполнителя)

- Имя пакета в импортах тестов — взять из `app/pubspec.yaml`.
- `ScanFailure` — сверить фактический конструктор/фабрику в `core/error/failure.dart`.
- `supabaseClientProvider` — сверить имя в `core/supabase/supabase_providers.dart`.
- `AppListTile.leading` — если нет такого параметра, подсветку low-confidence дать иным
  разрешённым каталогом способом (см. `shared/components`, design-system.md).
- `processReceiptPhoto(Uint8List(8))` в тесте может бросить → photoPath=null (best-effort).
  Подстроить ассерт теста под фактическое поведение, не ослабляя проверку id.
- Realtime в Supabase требует включённой публикации на таблицах `receipts`/`receipt_items`
  (Realtime). Это серверная настройка проекта (вне кода) — проверить при ручной проверке на
  устройстве; юнит-тесты используют фейковые стримы.
- ScanController использует `StreamSubscription` + `ref.onDispose` — убедиться, что в
  AsyncNotifier-стиле codegen это допустимо (подписка в методе, не в `build`).
