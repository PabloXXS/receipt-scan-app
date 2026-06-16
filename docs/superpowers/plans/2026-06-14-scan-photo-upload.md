# Scan Photo Upload Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** При сохранении скана загружать снятое/выбранное фото чека в приватный бакет Storage `receipts` и проставлять `receipts.photo_path`, чтобы список и детали показывали изображение.

**Architecture:** Байты фото кэшируются в приватном поле `ScanController` (заполняются в `recognizePhoto`, чистятся в `reset`) и передаются в `save()` → usecase → репозиторий. Репозиторий оркеструет: сжать в JPEG (`core/images/receipt_image_processor.dart`) → `uploadPhoto` (best-effort) → `insertReceiptWithItems(draft, photoPath)`. RLS у `receipts` запрещает клиентский UPDATE, поэтому `photo_path` ставится в INSERT (загрузка до insert). Отображение в receipts уже готово (signed URL + плейсхолдер).

**Tech Stack:** Flutter, Riverpod (codegen), supabase_flutter (Storage `uploadBinary`), package:image (^4.2.0, JPEG-кодек), flutter_test.

**Спецификация:** `docs/superpowers/specs/2026-06-14-scan-photo-upload-design.md`

**Общие правила:**
- Пакет импорта: `package:ticket_app/...`. Команды — из каталога `app/`.
- Каждый новый файл — с dartdoc-шапкой (`Назначение/Слой/Зависимости/Ключевые типы`).
- TDD: падающий тест → запуск (fail) → реализация → запуск (pass) → коммит.
- `dart format` — авто-хуком; `dart analyze` обязан быть чист (unused import = ошибка).
- Коммиты с трейлером `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## Структура файлов

**Создать:**
- `app/lib/core/images/receipt_image_processor.dart` — `processReceiptPhoto`.
- `app/test/core/images/receipt_image_processor_test.dart`.

**Изменить:**
- `app/lib/features/scan/domain/repositories/scan_repository.dart` — параметр `photoBytes`.
- `app/lib/features/scan/domain/usecases/save_scanned_receipt.dart` — проброс `photoBytes`.
- `app/lib/features/scan/data/datasources/scan_remote_datasource.dart` — `uploadPhoto` + `photoPath` в insert.
- `app/lib/features/scan/data/repositories/scan_repository_impl.dart` — оркестрация process→upload→insert.
- `app/test/features/scan/scan_test_fakes.dart` — `FakeScanRepository` фиксирует `photoBytes`.
- `app/test/features/scan/data/repositories/save_scanned_receipt_test.dart` — обновить `_FakeDs`, добавить тесты фото.
- `app/lib/features/scan/presentation/controllers/scan_controller.dart` — поле `_photoBytes`.
- `app/test/features/scan/presentation/controllers/scan_controller_test.dart` — тест передачи фото.
- `docs/features/scan.md`, `docs/features/receipts.md` — живая документация.

---

## Task 1: `processReceiptPhoto` (сжатие в JPEG)

**Files:**
- Create: `app/lib/core/images/receipt_image_processor.dart`
- Test: `app/test/core/images/receipt_image_processor_test.dart`

- [ ] **Step 1: Падающий тест**

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_app/core/images/receipt_image_processor.dart';

void main() {
  test('валидное изображение → непустой JPEG', () {
    final png = Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 20)));
    final out = processReceiptPhoto(png);
    expect(out, isNotEmpty);
    final decoded = img.decodeImage(out);
    expect(decoded, isNotNull);
  });

  test('большое изображение ужимается до kReceiptPhotoMaxSide по большей стороне', () {
    final png =
        Uint8List.fromList(img.encodePng(img.Image(width: 4000, height: 2000)));
    final decoded = img.decodeImage(processReceiptPhoto(png))!;
    expect(decoded.width, kReceiptPhotoMaxSide); // 4000 → 1600
    expect(decoded.height, 800); // пропорции сохранены
  });

  test('маленькое изображение не увеличивается', () {
    final png = Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 50)));
    final decoded = img.decodeImage(processReceiptPhoto(png))!;
    expect(decoded.width, 100);
    expect(decoded.height, 50);
  });

  test('не-изображение → FormatException', () {
    expect(() => processReceiptPhoto(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<FormatException>()));
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/core/images/receipt_image_processor_test.dart`
Expected: FAIL (URI target не существует / `processReceiptPhoto` не определён).

- [ ] **Step 3: Реализовать**

```dart
/// Назначение: подготовка фото чека к загрузке (даунскейл по большей стороне, JPEG).
///
/// Слой: core/images
/// Зависимости: dart:typed_data, package:image.
/// Ключевые типы: processReceiptPhoto, kReceiptPhotoMaxSide.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Максимальная сторона фото чека в пикселях.
const int kReceiptPhotoMaxSide = 1600;

/// Декодирует [input], ужимает по большей стороне до [kReceiptPhotoMaxSide]
/// с сохранением пропорций (если больше) и кодирует в JPEG (q=80).
/// Бросает [FormatException], если [input] — не изображение.
Uint8List processReceiptPhoto(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать изображение');
  }
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longest > kReceiptPhotoMaxSide
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? kReceiptPhotoMaxSide : null,
          height: decoded.height > decoded.width ? kReceiptPhotoMaxSide : null,
        )
      : decoded;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/core/images/receipt_image_processor_test.dart`
Expected: PASS (4 теста).

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/images/receipt_image_processor.dart app/test/core/images/receipt_image_processor_test.dart
git commit -m "feat(scan): процессор сжатия фото чека в JPEG"
```

---

## Task 2: Проброс фото через слои (domain + data) + загрузка в Storage

**Files:**
- Modify: `app/lib/features/scan/domain/repositories/scan_repository.dart`
- Modify: `app/lib/features/scan/domain/usecases/save_scanned_receipt.dart`
- Modify: `app/lib/features/scan/data/datasources/scan_remote_datasource.dart`
- Modify: `app/lib/features/scan/data/repositories/scan_repository_impl.dart`
- Modify: `app/test/features/scan/scan_test_fakes.dart`
- Modify/Test: `app/test/features/scan/data/repositories/save_scanned_receipt_test.dart`

> Сигнатуры интерфейсов меняются, поэтому все реализаторы и фейки правятся
> атомарно (иначе не компилируется). Порядок шагов выстроен так, чтобы после
> каждого коммита проект собирался.

- [ ] **Step 1: Обновить тест репозитория (падающий) — фейк-datasource + сценарии фото**

Заменить содержимое `app/test/features/scan/data/repositories/save_scanned_receipt_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

import '../../scan_test_fakes.dart';

class _FakeDs implements ScanRemoteDataSource {
  Object? error; // ошибка insert
  Object? uploadError; // ошибка upload
  ReceiptDraft? saved;
  String? insertedPhotoPath;
  int uploadCalls = 0;

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    uploadCalls++;
    if (uploadError != null) throw uploadError!;
    return 'uid/123.jpg';
  }

  @override
  Future<String> insertReceiptWithItems(
    ReceiptDraft draft, {
    String? photoPath,
  }) async {
    saved = draft;
    insertedPhotoPath = photoPath;
    if (error != null) throw error!;
    return 'rid-9';
  }
}

void main() {
  const draft = ReceiptDraft(items: [
    ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
  ], total: 2, qrRaw: 'УИ');

  test('saveScannedReceipt передаёт draft и возвращает id', () async {
    final ds = _FakeDs();
    final id = await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(id, 'rid-9');
    expect(ds.saved, same(draft));
  });

  test('без photoBytes upload не вызывается, photoPath=null', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(ds.uploadCalls, 0);
    expect(ds.insertedPhotoPath, isNull);
  });

  test('с photoBytes: фото грузится, путь попадает в insert', () async {
    final ds = _FakeDs();
    await ScanRepositoryImpl(ds)
        .saveScannedReceipt(draft, photoBytes: kValidPngBytes);
    expect(ds.uploadCalls, 1);
    expect(ds.insertedPhotoPath, 'uid/123.jpg');
  });

  test('ошибка загрузки фото → чек сохраняется без фото (best-effort)', () async {
    final ds = _FakeDs()..uploadError = const StorageException('boom');
    final id = await ScanRepositoryImpl(ds)
        .saveScannedReceipt(draft, photoBytes: kValidPngBytes);
    expect(id, 'rid-9');
    expect(ds.insertedPhotoPath, isNull);
  });

  test('ошибка insert → UploadFailure', () async {
    final ds = _FakeDs()..error = const PostgrestException(message: 'x');
    await expectLater(
      () => ScanRepositoryImpl(ds).saveScannedReceipt(draft),
      throwsA(isA<UploadFailure>()),
    );
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает (компиляция)**

Run: `cd app && flutter test test/features/scan/data/repositories/save_scanned_receipt_test.dart`
Expected: FAIL — компиляция: `uploadPhoto`/`photoPath`/`photoBytes` ещё не существуют.

- [ ] **Step 3: Обновить контракт `ScanRepository`**

В `app/lib/features/scan/domain/repositories/scan_repository.dart` заменить:

```dart
/// Назначение: контракт создания чека из результата сканирования.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, domain/entities/receipt_draft.dart.
/// Ключевые типы: ScanRepository.
library;

import 'dart:typed_data';

import '../entities/receipt_draft.dart';

/// Контракт сценариев сканирования. Реализация — в слое data.
abstract interface class ScanRepository {
  /// Сохраняет распознанный чек: (опц.) загрузка фото в Storage → insert
  /// receipts + receipt_items. Возвращает id чека.
  Future<String> saveScannedReceipt(ReceiptDraft draft, {Uint8List? photoBytes});

  // TODO(scan-qr): createReceiptFromQr(String raw) — отдельный цикл (скан QR-кода).
}
```

- [ ] **Step 4: Обновить usecase `SaveScannedReceipt`**

В `app/lib/features/scan/domain/usecases/save_scanned_receipt.dart` заменить тело класса:

```dart
/// Назначение: сценарий сохранения распознанного чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, entities/receipt_draft.dart,
///   repositories/scan_repository.dart.
/// Ключевые типы: SaveScannedReceipt.
library;

import 'dart:typed_data';

import '../entities/receipt_draft.dart';
import '../repositories/scan_repository.dart';

/// Сохраняет распознанный чек (с опциональным фото). Возвращает id чека.
class SaveScannedReceipt {
  const SaveScannedReceipt(this._repo);
  final ScanRepository _repo;

  Future<String> call(ReceiptDraft draft, {Uint8List? photoBytes}) =>
      _repo.saveScannedReceipt(draft, photoBytes: photoBytes);
}
```

- [ ] **Step 5: Обновить datasource (interface + Supabase impl)**

В `app/lib/features/scan/data/datasources/scan_remote_datasource.dart`:
добавить `import 'dart:typed_data';` в начало импортов; заменить интерфейс и impl:

```dart
/// Абстракция удалённых операций сканирования.
abstract interface class ScanRemoteDataSource {
  /// Загружает JPEG фото чека в приватный бакет `receipts`. Возвращает путь объекта.
  Future<String> uploadPhoto(Uint8List jpegBytes);

  /// Вставляет чек и его позиции (status=done). Возвращает id чека.
  Future<String> insertReceiptWithItems(ReceiptDraft draft, {String? photoPath});
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseScanRemoteDataSource implements ScanRemoteDataSource {
  const SupabaseScanRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'receipts';

  @override
  Future<String> uploadPhoto(Uint8List jpegBytes) async {
    final uid = _client.auth.currentUser!.id;
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          jpegBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return path;
  }

  @override
  Future<String> insertReceiptWithItems(
    ReceiptDraft draft, {
    String? photoPath,
  }) async {
    final receipt = await _client
        .from('receipts')
        .insert({
          'source': ScanSource.ocr.dbValue,
          'qr_raw': draft.qrRaw,
          'status': 'done',
          'total': draft.total,
          'purchased_at': draft.purchasedAt?.toIso8601String(),
          'photo_path': photoPath,
        })
        .select('id')
        .single();
    final id = receipt['id'] as String;
    if (draft.items.isNotEmpty) {
      await _client.from('receipt_items').insert([
        for (final it in draft.items)
          {
            'receipt_id': id,
            'raw_name': it.rawName,
            'qty': it.qty,
            'unit_price': it.unitPrice,
            'sum': it.sum,
          },
      ]);
    }
    return id;
  }
}
```

(Провайдер `scanRemoteDataSourceProvider` в конце файла не меняется. Обнови
доку-шапку файла: добавь в «Ключевые типы» наличие `uploadPhoto`, если уместно.)

- [ ] **Step 6: Обновить репозиторий (оркестрация)**

Заменить тело `ScanRepositoryImpl` в `app/lib/features/scan/data/repositories/scan_repository_impl.dart`
(добавить импорты `dart:typed_data` и процессора):

```dart
/// Назначение: реализация ScanRepository (опц. фото → Storage; insert receipts + items).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, core/images/receipt_image_processor.dart,
///   datasources/scan_remote_datasource.dart, scan_error_mapper.dart,
///   domain/repositories/scan_repository.dart.
/// Ключевые типы: ScanRepositoryImpl, scanRepositoryProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/receipt_image_processor.dart';
import '../../domain/entities/receipt_draft.dart';
import '../../domain/repositories/scan_repository.dart';
import '../datasources/scan_remote_datasource.dart';
import '../scan_error_mapper.dart';

/// Сохраняет распознанный чек через datasource. Фото — best-effort. Ошибки → ScanFailure.
class ScanRepositoryImpl implements ScanRepository {
  const ScanRepositoryImpl(this._ds);

  final ScanRemoteDataSource _ds;

  @override
  Future<String> saveScannedReceipt(
    ReceiptDraft draft, {
    Uint8List? photoBytes,
  }) async {
    try {
      String? photoPath;
      if (photoBytes != null) {
        // Best-effort: сжатие или загрузка фото не должны срывать сохранение чека.
        try {
          final jpeg = processReceiptPhoto(photoBytes);
          photoPath = await _ds.uploadPhoto(jpeg);
        } catch (_) {
          photoPath = null;
        }
      }
      return await _ds.insertReceiptWithItems(draft, photoPath: photoPath);
    } catch (e) {
      throw mapScanException(e);
    }
  }
}

/// DI-провайдер репозитория сканирования.
final scanRepositoryProvider = Provider<ScanRepository>(
  (ref) => ScanRepositoryImpl(ref.watch(scanRemoteDataSourceProvider)),
);
```

- [ ] **Step 7: Обновить `FakeScanRepository`**

В `app/test/features/scan/scan_test_fakes.dart` добавить `import 'dart:typed_data';`
(уже есть) и заменить `FakeScanRepository`:

```dart
/// Фейк репозитория сканирования: опционально кидает ошибку, фиксирует фото.
class FakeScanRepository implements ScanRepository {
  Object? error;
  String receiptId = 'rid-1';
  Uint8List? receivedPhotoBytes;

  @override
  Future<String> saveScannedReceipt(
    ReceiptDraft draft, {
    Uint8List? photoBytes,
  }) async {
    if (error != null) throw error!;
    receivedPhotoBytes = photoBytes;
    return receiptId;
  }
}
```

- [ ] **Step 8: Запустить — репозиторный тест зелёный + анализ**

Run: `cd app && dart analyze lib/features/scan test/features/scan && flutter test test/features/scan/data/repositories/save_scanned_receipt_test.dart`
Expected: анализ без ошибок; 5 тестов PASS.

- [ ] **Step 9: Commit**

```bash
git add app/lib/features/scan/domain/repositories/scan_repository.dart \
  app/lib/features/scan/domain/usecases/save_scanned_receipt.dart \
  app/lib/features/scan/data/datasources/scan_remote_datasource.dart \
  app/lib/features/scan/data/repositories/scan_repository_impl.dart \
  app/test/features/scan/scan_test_fakes.dart \
  app/test/features/scan/data/repositories/save_scanned_receipt_test.dart
git commit -m "feat(scan): загрузка фото чека в Storage и проброс photo_path в insert"
```

---

## Task 3: `ScanController` — кэш байтов фото и передача в save

**Files:**
- Modify: `app/lib/features/scan/presentation/controllers/scan_controller.dart`
- Test: `app/test/features/scan/presentation/controllers/scan_controller_test.dart`

- [ ] **Step 1: Падающий тест**

Добавить в `app/test/features/scan/presentation/controllers/scan_controller_test.dart`
новый тест перед закрывающей `}` функции `main` (рядом с остальными):

```dart
  test('save передаёт байты фото в репозиторий', () async {
    final repo = FakeScanRepository();
    final c = _c(repo: repo);
    final n = c.read(scanControllerProvider.notifier);
    await n.recognizePhoto(kValidPngBytes);
    await n.save();
    expect(repo.receivedPhotoBytes, isNotNull);
    expect(repo.receivedPhotoBytes, same(kValidPngBytes));
  });
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/scan/presentation/controllers/scan_controller_test.dart --plain-name "save передаёт байты фото"`
Expected: FAIL — `receivedPhotoBytes` равно null (фото пока не пробрасывается).

- [ ] **Step 3: Реализовать в контроллере**

В `app/lib/features/scan/presentation/controllers/scan_controller.dart`:

1) Добавить импорт `import 'dart:typed_data';` (уже есть — он импортируется в файле; если нет, добавить).

2) В классе `ScanController` добавить приватное поле сразу после `build`:

```dart
  /// Байты последнего распознанного фото (для загрузки при сохранении).
  Uint8List? _photoBytes;
```

3) В `recognizePhoto` сохранить байты в начале метода:

```dart
  Future<void> recognizePhoto(Uint8List bytes) async {
    _photoBytes = bytes;
    state = const ScanRecognizing();
    try {
      final ocr = await ref.read(receiptOcrEngineProvider).recognize(bytes);
      state = ScanReview(ref.read(receiptParserProvider).parse(ocr));
    } catch (e) {
      state = ScanError(mapScanException(e));
    }
  }
```

4) В `save` передать байты в usecase (строка вызова):

```dart
      final id = await SaveScannedReceipt(ref.read(scanRepositoryProvider))(
        draft,
        photoBytes: _photoBytes,
      );
```

5) В `reset` очистить байты:

```dart
  /// Сброс к началу.
  void reset() {
    _photoBytes = null;
    state = const ScanIdle();
  }
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/scan/presentation/controllers/scan_controller_test.dart`
Expected: PASS (все тесты файла, включая новый).

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/presentation/controllers/scan_controller.dart \
  app/test/features/scan/presentation/controllers/scan_controller_test.dart
git commit -m "feat(scan): передавать снятое/выбранное фото в сохранение чека"
```

---

## Task 4: Живая документация

**Files:**
- Modify: `docs/features/scan.md`
- Modify: `docs/features/receipts.md`

- [ ] **Step 1: Обновить `docs/features/scan.md`**

Добавить (в разделе про сохранение/обработку): при сохранении скана фото
сжимается в JPEG (`core/images/receipt_image_processor.dart`, ≤1600px, q80) и
грузится в приватный бакет `receipts` по пути `{uid}/{ts}.jpg`; `photo_path`
проставляется в INSERT (клиентский UPDATE у `receipts` запрещён RLS). Загрузка —
best-effort: при ошибке сжатия/загрузки чек сохраняется с `photo_path=null`.
Известное ограничение: при падении INSERT после успешной загрузки фото остаётся
осиротевшим в бакете (чистка — отдельная задача).

- [ ] **Step 2: Обновить `docs/features/receipts.md`**

В разделе «Экраны / UI» (про миниатюру/детали) отметить: для чеков, сохранённых
через скан, теперь отображается реальное фото (signed URL по `photo_path`);
плейсхолдер — только если фото не загрузилось.

- [ ] **Step 3: Commit**

```bash
git add docs/features/scan.md docs/features/receipts.md
git commit -m "docs(scan,receipts): загрузка и отображение фото чека"
```

---

## Финальная верификация

- [ ] **Полный прогон**

Run: `cd app && dart analyze && flutter test`
Expected: No issues found (для затронутых файлов); все тесты PASS.

- [ ] **Ручная проверка на устройстве/симуляторе**

Скан из галереи → сохранить → на вкладке «Чеки» у нового чека видна миниатюра;
тап → в деталях видно фото. Проверить также живую камеру. (Если фото не
загрузилось — должен быть плейсхолдер, чек всё равно в списке.)

---

## Self-Review (выполнено автором плана)

- **Покрытие спека:** процессор JPEG (Task 1); контракт+usecase+datasource+repo
  оркестрация+фейки (Task 2); загрузка до insert и `photo_path` в insert (Task 2,
  Step 5–6); best-effort при ошибке (Task 2, repo + тест); кэш байтов в контроллере
  (Task 3); отображение — без изменений (готово ранее); документация (Task 4);
  известное ограничение про осиротевшее фото — задокументировано. Пробелов нет.
- **Плейсхолдеры:** отсутствуют; весь код приведён.
- **Согласованность типов:** `processReceiptPhoto`/`kReceiptPhotoMaxSide`,
  `ScanRepository.saveScannedReceipt(draft,{photoBytes})`,
  `SaveScannedReceipt.call(draft,{photoBytes})`,
  `ScanRemoteDataSource.uploadPhoto`/`insertReceiptWithItems(draft,{photoPath})`,
  `FakeScanRepository.receivedPhotoBytes`, `_FakeDs` — имена согласованы между
  задачами. Сигнатуры меняются атомарно (Task 2) — нет битых промежуточных сборок.
