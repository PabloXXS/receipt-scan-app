# Живое превью камеры (Фаза 2, iOS) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Снимать чек живой камерой внутри приложения (превью + затвор) и отдавать снимок в существующий OCR-конвейер Фазы 1.

**Architecture:** Плагин `camera` (AVFoundation), экран `LiveCameraScreen` инкапсулирует превью и съёмку; контроллер получает готовые байты через новый публичный `recognizePhoto(Uint8List)` и остаётся тестируемым. Галерея (`image_picker`) сохраняется. iOS-only; реальная съёмка — только на устройстве.

**Tech Stack:** Flutter, Riverpod (codegen), плагин `camera`, существующий Apple Vision OCR. Тесты — `flutter_test` + фейки.

Спек: [docs/superpowers/specs/2026-06-14-live-camera-design.md](../specs/2026-06-14-live-camera-design.md). Пакет — `ticket_app`. Команды Flutter — из `app/`.

---

### Task 1: Подключить плагин `camera`

**Files:**
- Modify: `app/pubspec.yaml`, `app/pubspec.lock`

- [ ] **Step 1: Добавить зависимость**

Run: `cd app && flutter pub add camera`
Expected: `camera` появился в `dependencies` pubspec.yaml; `pub get` прошёл успешно.

- [ ] **Step 2: Проверить разрешение зависимостей**

Run: `cd app && flutter pub get`
Expected: `Got dependencies!` без конфликтов версий.

- [ ] **Step 3: Commit**

```bash
git add app/pubspec.yaml app/pubspec.lock
git commit -m "feat(scan): подключить плагин camera"
```

---

### Task 2: Контроллер — `recognizePhoto`; убрать image_picker-камеру

**Files:**
- Modify: `app/lib/features/scan/presentation/controllers/scan_controller.dart`
- Regenerate: `scan_controller.g.dart`
- Modify: `app/test/features/scan/scan_test_fakes.dart` (`FakeOcrEngine` — поддержка ошибки)
- Modify: `app/test/features/scan/presentation/controllers/scan_controller_test.dart`
- Modify: `app/lib/features/scan/presentation/widgets/scan_capture_view.dart`
- Modify: `app/test/features/scan/presentation/screens/scan_screen_test.dart`

- [ ] **Step 1: Переписать `scan_controller.dart` целиком**

```dart
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
```

- [ ] **Step 2: Поддержать ошибку в `FakeOcrEngine`**

В `app/test/features/scan/scan_test_fakes.dart` заменить класс `FakeOcrEngine` на:
```dart
/// Фейк движка OCR — отдаёт заранее заданный результат или кидает [error].
class FakeOcrEngine implements ReceiptOcrEngine {
  FakeOcrEngine(this.result, {this.error});
  final OcrResult result;
  final Object? error;
  @override
  Future<OcrResult> recognize(Uint8List photoBytes) async {
    if (error != null) throw error!;
    return result;
  }
}
```

- [ ] **Step 3: Переписать тест контроллера целиком**

`app/test/features/scan/presentation/controllers/scan_controller_test.dart`:
```dart
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
    photoPickerProvider
        .overrideWithValue(picker ?? (FakePhotoPicker()..result = kValidPngBytes)),
    receiptOcrEngineProvider.overrideWithValue(
        engine ?? FakeOcrEngine(const OcrResult(lines: prostoreOcrLines, qr: 'УИ'))),
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
    await c.read(scanControllerProvider.notifier).recognizePhoto(kValidPngBytes);
    final s = c.read(scanControllerProvider);
    expect(s, isA<ScanReview>());
    expect((s as ScanReview).draft.items.length, 14);
  });

  test('ошибка движка OCR → ScanError', () async {
    final c = _c(
      engine: FakeOcrEngine(const OcrResult(lines: []), error: Exception('boom')),
    );
    await c.read(scanControllerProvider.notifier).recognizePhoto(kValidPngBytes);
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
    expect((c.read(scanControllerProvider) as ScanReview).draft.items.length, 13);
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
}
```

- [ ] **Step 4: Убрать кнопку image_picker-камеры из `scan_capture_view.dart`**

Заменить блок кнопок (оставить только галерею; кнопку «Камера» добавим в Task 4):
```dart
          SizedBox(height: tokens.spaceXl),
          AppButton(
            label: 'Из галереи',
            icon: Icons.photo_library,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: controller.pickFromGallery,
          ),
```
(Удаляется кнопка «Сфотографировать» с `controller.pickFromCamera` — этого метода больше нет.)

- [ ] **Step 5: Обновить widget-тест экрана на галерейный путь**

В `app/test/features/scan/presentation/screens/scan_screen_test.dart` заменить нажатие
`find.text('Сфотографировать')` на `find.text('Из галереи')` (остальное без изменений):
```dart
    expect(find.text('Из галереи'), findsOneWidget);
    await tester.tap(find.text('Из галереи'));
    await tester.pumpAndSettle();

    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сканировать ещё'), findsOneWidget);
```

- [ ] **Step 6: Codegen + тесты**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: успех (сигнатуры провайдеров не изменились, но прогон обязателен).
Run: `cd app && flutter test test/features/scan`
Expected: PASS (контроллер 8 тестов, экран — галерейный путь зелёный).

- [ ] **Step 7: Commit**

```bash
git add app/lib/features/scan/presentation/controllers/scan_controller.dart app/lib/features/scan/presentation/controllers/scan_controller.g.dart app/test/features/scan/scan_test_fakes.dart app/test/features/scan/presentation/controllers/scan_controller_test.dart app/lib/features/scan/presentation/widgets/scan_capture_view.dart app/test/features/scan/presentation/screens/scan_screen_test.dart
git commit -m "refactor(scan): публичный recognizePhoto; убрать image_picker-камеру"
```

---

### Task 3: Экран живой камеры `LiveCameraScreen`

**Files:**
- Create: `app/lib/features/scan/presentation/screens/live_camera_screen.dart`

> Плагин `camera` требует платформу — экран проверяется на реальном iPhone (Task 5); юнит/widget-тестом не покрывается.

- [ ] **Step 1: Создать `live_camera_screen.dart`**

```dart
/// Назначение: живое превью камеры в приложении + съёмка чека для OCR.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: dart:typed_data, flutter, flutter_riverpod, camera,
///   shared/components, core/theme, presentation/controllers/scan_controller.dart.
/// Ключевые типы: LiveCameraScreen.
library;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';

/// Экран живой камеры: превью + затвор. Снимок → recognizePhoto → возврат на скан.
class LiveCameraScreen extends ConsumerStatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  ConsumerState<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends ConsumerState<LiveCameraScreen> {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'Камера недоступна. Используйте «Из галереи».');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      setState(() =>
          _error = 'Нет доступа к камере (${e.code}). Разрешите в настройках.');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      // Не ждём распознавание: состояние контроллера ведёт ScanScreen после возврата.
      ref.read(scanControllerProvider.notifier).recognizePhoto(bytes);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось сделать снимок. Попробуйте ещё раз.';
          _capturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controller = _controller;

    final Widget body;
    if (_error != null) {
      body = Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: AppErrorView(message: _error!),
      );
    } else if (controller == null) {
      body = const AppLoader();
    } else {
      body = Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceXl),
              child: AppButton(
                label: 'Снять',
                icon: Icons.camera,
                expanded: true,
                loading: _capturing,
                onPressed: _capturing ? null : _capture,
              ),
            ),
          ),
        ],
      );
    }

    return AppScaffold(title: 'Камера', body: body);
  }
}
```

- [ ] **Step 2: Проверить анализ**

Run: `cd app && dart analyze lib/features/scan/presentation/screens/live_camera_screen.dart`
Expected: No issues found. Если API плагина `camera` отличается (`availableCameras`, `CameraController`, `ResolutionPreset`, `CameraPreview`, `takePicture`) — сверься с установленной версией (`app/pubspec.lock`) и приведи вызовы к ней; UI-примитивы бери только из каталога (`AppScaffold/AppButton/AppErrorView/AppLoader`), `CameraPreview` — это виджет плагина (каталожного аналога нет).

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/scan/presentation/screens/live_camera_screen.dart
git commit -m "feat(scan): экран живой камеры (превью + затвор)"
```

---

### Task 4: Кнопка «Камера» → `LiveCameraScreen`

**Files:**
- Modify: `app/lib/features/scan/presentation/widgets/scan_capture_view.dart`

- [ ] **Step 1: Добавить кнопку «Камера»**

В `scan_capture_view.dart` добавить импорт экрана и кнопку «Камера» ПЕРЕД кнопкой «Из галереи».
Импорт (рядом с другими):
```dart
import '../screens/live_camera_screen.dart';
```
Блок кнопок:
```dart
          SizedBox(height: tokens.spaceXl),
          AppButton(
            label: 'Камера',
            icon: Icons.photo_camera,
            expanded: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LiveCameraScreen(),
              ),
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          AppButton(
            label: 'Из галереи',
            icon: Icons.photo_library,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: controller.pickFromGallery,
          ),
```

- [ ] **Step 2: Анализ и тесты**

Run: `cd app && dart analyze && flutter test`
Expected: `No issues found.` и все тесты PASS (widget-тест экрана идёт по «Из галереи», кнопка «Камера» лишь навигирует — на неё тест не нажимает).

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/scan/presentation/widgets/scan_capture_view.dart
git commit -m "feat(scan): кнопка «Камера» открывает живое превью"
```

---

### Task 5: Документация и ручная проверка на устройстве

**Files:**
- Modify: `docs/features/scan.md`

- [ ] **Step 1: Обновить `docs/features/scan.md`**

В разделе «Открытые вопросы / отложено» убрать пункт про Фазу 2 и добавить запись о реализации.
Заменить строку:
```markdown
- **Фаза 2:** живое AVFoundation-превью с real-time QR-оверлеем.
```
на:
```markdown
- **Фаза 2 (реализовано, цикл 2026-06-14):** живое превью камеры в приложении
  (плагин `camera`) + затвор → существующий OCR-конвейер. Захват фото вынесен в
  `LiveCameraScreen`; контроллер принимает байты через `recognizePhoto`. Real-time
  QR-оверлей сознательно не делался.
```

- [ ] **Step 2: Полная проверка**

Run: `cd app && dart analyze && flutter test`
Expected: `No issues found.` и все тесты PASS.

- [ ] **Step 3: Ручная проверка на реальном iPhone**

Собрать на устройстве (`cd app && ./run-dev.sh <device-id>`; список — `flutter devices`).
Войти → вкладка «Скан» → «Камера» → дать доступ к камере → навести на чек → «Снять» →
дождаться распознавания → ревью позиций → «Сохранить».
Проверить запись (supabase MCP `execute_sql`):
```sql
select r.id, r.status, r.source,
       (select count(*) from public.receipt_items i where i.receipt_id = r.id) as items
from public.receipts r where r.source='ocr' order by r.created_at desc limit 1;
```
Ожидаем `status='done'`, `items > 0`.
> Симулятор не подойдёт для съёмки (нет камеры) — там доступен только путь «Из галереи».

- [ ] **Step 4: Commit**

```bash
git add docs/features/scan.md
git commit -m "docs(scan): Фаза 2 — живое превью камеры"
```

---

## Self-Review

**1. Покрытие спека:**
- §1 объём (живое превью + затвор → OCR-конвейер; галерея сохранена; iOS) → Tasks 1–4. ✅
- §2 плагин `camera` → Task 1; `LiveCameraScreen` → Task 3; `recognizePhoto` рефактор → Task 2; кнопка «Камера» / галерея без изменений → Task 4/Task 2. ✅
- §2 удаление image_picker-камеры → Task 2. ✅
- §3 машина состояний не меняется → подтверждено (Task 2 сохраняет состояния). ✅
- §4 ошибки (нет доступа/нет камеры/сбой съёмки) → Task 3 (`_error`); OCR/save-ошибки — прежние. ✅
- §5 тесты (`recognizePhoto` юнит, галерейный widget-тест, камера — вручную) → Tasks 2, 5. ✅
- §6 риски (камера только на устройстве, рефактор `_capture`) → отражены (Task 3/5; поведение галереи покрыто тестами контроллера). ✅

**2. Плейсхолдеры:** нет — у каждого шага конкретный код/команда/ожидаемый вывод.

**3. Согласованность типов:** `ScanController.recognizePhoto(Uint8List)` — добавлен в Task 2, вызывается из `LiveCameraScreen` (Task 3) и `pickFromGallery` (Task 2). `pickFromCamera` удалён в Task 2 и больше нигде не упоминается (capture-view обновлён там же). `FakeOcrEngine(result, {error})` — расширен в Task 2, используется в тестах Task 2. Состояния `ScanIdle/…/ScanError` без изменений.
