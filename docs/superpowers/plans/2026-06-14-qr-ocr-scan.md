# Скан QR + OCR позиций (Фаза 1, iOS) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Снять фото чека (камера/галерея) → Apple Vision извлекает текст + QR → парсер строит позиции → экран-ревью → «Сохранить» пишет `receipts`+`receipt_items` в БД.

**Architecture:** iOS-only. Нативный Swift-метод `recognizeReceipt(bytes)→{lines,qr}` (VNRecognizeTextRequest ru + VNDetectBarcodesRequest) за `MethodChannel`. Захват фото — существующий `PhotoPicker` (image_picker). Парсер позиций — чистый Dart (главный тест). Сохранение — прямой insert (без Storage/pgmq). Живая камера/QR-оверлей — Фаза 2 (отдельный план).

**Tech Stack:** Flutter, Riverpod (codegen), Supabase (Postgres+RLS), Apple Vision (Swift), пакеты `image_picker` (уже есть). Новых pub-зависимостей нет.

Спек: [docs/superpowers/specs/2026-06-14-qr-ocr-scan-design.md](../specs/2026-06-14-qr-ocr-scan-design.md). Пакет — `ticket_app`. Команды Flutter — из `app/`.

**Замена старого пути:** Фаза 1 заменяет прежний flow «фото→Storage→pending» (цикл 2026-06-09) на OCR-путь. Старые presentation-файлы и неиспользуемый data-код удаляются в Task 11.

---

### Task 1: Миграция `0003_receipt_items` (+ валюта чека)

**Files:**
- Create: `supabase/migrations/0003_receipt_items.sql`

- [ ] **Step 1: Написать файл миграции**

```sql
-- Миграция: scan — таблица receipt_items (зона A) + валюта чека из страны.
-- Зона доступа: A. Инвариант приватности: зона A; в зону C (prices) ничего не уходит.

create table if not exists public.receipt_items (
  id          uuid primary key default gen_random_uuid(),
  receipt_id  uuid not null references public.receipts (id) on delete cascade,
  user_id     uuid not null references auth.users (id) on delete cascade,
  family_id   uuid,
  raw_name    text not null,
  product_id  uuid,                 -- FK на products добавим в reference-цикле
  qty         numeric(12, 3) not null default 1,
  unit_price  numeric(12, 2),
  sum         numeric(12, 2),
  created_at  timestamptz not null default now()
);

create index if not exists receipt_items_receipt_id_idx on public.receipt_items (receipt_id);
create index if not exists receipt_items_user_id_idx on public.receipt_items (user_id);

-- Автозаполнение владельца (как в receipts).
create or replace function public.receipt_items_fill_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  new.user_id := auth.uid();
  select p.family_id into new.family_id from public.profiles p where p.id = auth.uid();
  return new;
end; $$;

drop trigger if exists receipt_items_fill_owner_trg on public.receipt_items;
create trigger receipt_items_fill_owner_trg before insert on public.receipt_items
  for each row execute function public.receipt_items_fill_owner();

revoke execute on function public.receipt_items_fill_owner() from public, anon, authenticated;

alter table public.receipt_items enable row level security;

drop policy if exists "receipt_items_select_own" on public.receipt_items;
create policy "receipt_items_select_own" on public.receipt_items for select
  using (user_id = auth.uid());

drop policy if exists "receipt_items_insert_own" on public.receipt_items;
create policy "receipt_items_insert_own" on public.receipt_items for insert
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.receipts r
                where r.id = receipt_id and r.user_id = auth.uid())
  );

drop policy if exists "receipt_items_delete_own" on public.receipt_items;
create policy "receipt_items_delete_own" on public.receipt_items for delete
  using (user_id = auth.uid());

-- Дополняем receipts_fill_owner: валюта из country_code, если не задана клиентом.
create or replace function public.receipts_fill_owner()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  new.user_id := auth.uid();
  select p.country_code, p.family_id into new.country_code, new.family_id
    from public.profiles p where p.id = auth.uid();
  new.currency := coalesce(new.currency, case new.country_code
    when 'BY' then 'BYN' when 'RU' then 'RUB' when 'KZ' then 'KZT' else null end);
  return new;
end; $$;

revoke execute on function public.receipts_fill_owner() from public, anon, authenticated;
```

- [ ] **Step 2: Аудит субагентом `privacy-rls-reviewer`**

Затрагивается схема зоны A (`receipt_items`) и триггер `receipts_fill_owner`. Дождаться вердикта; при замечаниях исправить и повторить.

- [ ] **Step 3: Применить к dev-проекту**

Через supabase MCP `apply_migration` (project `yftrsgcqrzzmxbttlltz`, name `0003_receipt_items`, query — файл из Step 1).

- [ ] **Step 4: Проверить**

supabase MCP `execute_sql`:
```sql
select
  (select count(*) from information_schema.tables
     where table_schema='public' and table_name='receipt_items') as tbl,
  (select count(*) from pg_policies where tablename='receipt_items')  as policies,
  (select pg_get_functiondef('public.receipts_fill_owner'::regproc) like '%currency%') as currency_in_trg;
```
Expected: `tbl=1`, `policies=3`, `currency_in_trg=t`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/0003_receipt_items.sql
git commit -m "feat(scan): миграция receipt_items + валюта чека из страны"
```

---

### Task 2: Доменные сущности OCR и черновик чека

**Files:**
- Create: `app/lib/features/scan/domain/entities/ocr_result.dart`
- Create: `app/lib/features/scan/domain/entities/receipt_draft.dart`
- Test: `app/test/features/scan/domain/entities/receipt_draft_test.dart`

- [ ] **Step 1: Создать `ocr_result.dart`**

```dart
/// Назначение: результат OCR чека — упорядоченные строки текста и QR.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: OcrResult.
library;

/// Результат распознавания: строки сверху вниз и (опц.) полезная нагрузка QR.
class OcrResult {
  const OcrResult({required this.lines, this.qr});

  /// Строки текста в порядке сверху вниз.
  final List<String> lines;

  /// Содержимое QR (УИ), если найден.
  final String? qr;
}
```

- [ ] **Step 2: Написать падающий тест `receipt_draft_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

void main() {
  ReceiptDraft draft() => ReceiptDraft(
        items: const [
          ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
          ReceiptItemDraft(rawName: 'B', qty: 1, unitPrice: 3, sum: 3),
        ],
        total: 5,
        purchasedAt: DateTime(2026, 6, 10),
        qrRaw: 'УИ1',
      );

  test('itemsSum суммирует позиции', () {
    expect(draft().itemsSum, 5);
  });

  test('totalMatches=true когда сумма позиций ≈ total', () {
    expect(draft().totalMatches, isTrue);
  });

  test('removeItemAt возвращает новый draft без позиции', () {
    final d = draft().removeItemAt(0);
    expect(d.items.length, 1);
    expect(d.items.first.rawName, 'B');
    expect(d.total, 5); // печатный итог не пересчитываем
  });
}
```

- [ ] **Step 3: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/scan/domain/entities/receipt_draft_test.dart`
Expected: FAIL (типы не определены).

- [ ] **Step 4: Создать `receipt_draft.dart`**

```dart
/// Назначение: черновик распознанного чека и его позиций (до сохранения).
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: ReceiptDraft, ReceiptItemDraft.
library;

/// Одна распознанная позиция чека.
class ReceiptItemDraft {
  const ReceiptItemDraft({
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
  });

  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;
}

/// Распознанный чек: позиции, печатный итог, дата, УИ из QR.
class ReceiptDraft {
  const ReceiptDraft({
    required this.items,
    this.total,
    this.purchasedAt,
    this.qrRaw,
  });

  final List<ReceiptItemDraft> items;
  final double? total;
  final DateTime? purchasedAt;
  final String? qrRaw;

  /// Сумма распознанных позиций.
  double get itemsSum =>
      items.fold(0, (acc, it) => acc + it.sum);

  /// Сходится ли сумма позиций с печатным итогом (с копеечной погрешностью).
  bool get totalMatches =>
      total != null && (itemsSum - total!).abs() < 0.01;

  /// Возвращает копию без позиции [index] (печатный итог не пересчитывается).
  ReceiptDraft removeItemAt(int index) => ReceiptDraft(
        items: [...items]..removeAt(index),
        total: total,
        purchasedAt: purchasedAt,
        qrRaw: qrRaw,
      );
}
```

- [ ] **Step 5: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/scan/domain/entities/receipt_draft_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/scan/domain/entities/ocr_result.dart app/lib/features/scan/domain/entities/receipt_draft.dart app/test/features/scan/domain/entities/receipt_draft_test.dart
git commit -m "feat(scan): сущности OcrResult и ReceiptDraft"
```

---

### Task 3: Контракты движка OCR, парсера и репозитория

**Files:**
- Create: `app/lib/features/scan/domain/ocr/receipt_ocr_engine.dart`
- Create: `app/lib/features/scan/domain/ocr/receipt_parser.dart`
- Modify: `app/lib/features/scan/domain/repositories/scan_repository.dart`

> Чистые интерфейсы — проверяет `dart analyze` и зависимые задачи.

- [ ] **Step 1: Создать `receipt_ocr_engine.dart`**

```dart
/// Назначение: контракт движка распознавания чека по фото.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, entities/ocr_result.dart.
/// Ключевые типы: ReceiptOcrEngine.
library;

import 'dart:typed_data';

import '../entities/ocr_result.dart';

/// Распознаёт текст и QR чека по байтам фото. Vision-реализация сейчас,
/// LLM-реализация — будущая платная фича.
abstract interface class ReceiptOcrEngine {
  Future<OcrResult> recognize(Uint8List photoBytes);
}
```

- [ ] **Step 2: Создать `receipt_parser.dart`**

```dart
/// Назначение: контракт парсера строк OCR в черновик чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: entities/ocr_result.dart, entities/receipt_draft.dart.
/// Ключевые типы: ReceiptParser.
library;

import '../entities/ocr_result.dart';
import '../entities/receipt_draft.dart';

/// Преобразует результат OCR в [ReceiptDraft].
abstract interface class ReceiptParser {
  ReceiptDraft parse(OcrResult ocr);
}
```

- [ ] **Step 3: Добавить метод в `scan_repository.dart`**

В `app/lib/features/scan/domain/repositories/scan_repository.dart` добавить в интерфейс `ScanRepository` (рядом с `createReceiptFromPhoto`, импорт `receipt_draft.dart`):

```dart
  /// Сохраняет распознанный чек: insert receipts + receipt_items. Возвращает id.
  Future<String> saveScannedReceipt(ReceiptDraft draft);
```
И добавить вверх импорт:
```dart
import '../entities/receipt_draft.dart';
```

- [ ] **Step 4: Проверить анализ**

Run: `cd app && dart analyze lib/features/scan/domain`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/domain/ocr/ app/lib/features/scan/domain/repositories/scan_repository.dart
git commit -m "feat(scan): контракты ReceiptOcrEngine, ReceiptParser, saveScannedReceipt"
```

---

### Task 4: Фикстура OCR реального чека (ProStore)

**Files:**
- Create: `app/test/features/scan/prostore_ocr_fixture.dart`

> Приближение строк Apple Vision для чека ProStore из `assets/` (14 позиций, итог 65.89). Используется тестами парсера и контроллера. Реальная точность тюнится на устройстве (Фаза 2).

- [ ] **Step 1: Создать фикстуру**

```dart
/// Приближение выдачи Apple Vision для тестового чека ProStore (assets/receipt-*).
/// Строки сверху вниз; формат позиции: «код Название» (+ переносы) и «цена *кол-во итог».
const List<String> prostoreOcrLines = [
  'ProStore',
  'Гипермаркет "ProStore" Малиновка',
  'г. Минск пр. ДЗЕРЖИНСКОГО, 126',
  'УНП 193854962  РН СККО 119093043',
  'N док. 110180',
  'Цена Кол-во Итого',
  '5449000131843 Напиток Coca-Cola без сахара',
  'безалк газ 2л ПЭТ',
  '5.49 *1.000 5.49',
  '4814720012856 Пакет-майка БИО, с логотипом 2+0,',
  'размер пакета 360*600',
  '0.19 *1.000 0.19',
  '4680021880490 Печенье сдобное Американское 200г',
  '3.64 *1.000 3.64',
  '4680021880490 Печенье сдобное Американское 200г',
  '3.64 *1.000 3.64',
  '4600528357981 Соус бургер-соус Astoria 200г',
  'дой-пак',
  '4.89 *1.000 4.89',
  '2240748 Рулет Праздничный к/в в/с Петруха',
  'флоупак вес 1кг Юнимит',
  '15.77 *0.562 8.86',
  '[M] 4607037122352 Сыр плав President Чеддер 40%',
  'слайсы 150г',
  '5.99 *1.000 5.99',
  '2204091 Фарш говяжий полуфабрикат вес',
  '21.99 *0.488 10.73',
  '4811529000022 Салат листовой в стаканчике 1 шт',
  'Минский парниково-тепличный комбинат',
  '1.99 *1.000 1.99',
  '4650068400036 Томат сливовидный красный Фламенко',
  'фас 450гр Импорт',
  '7.91 *1.000 7.91',
  '4601674084851 Кетчуп Heinz томатный с горчицей',
  '320г дой пак',
  '4.49 *1.000 4.49',
  '4670005830962 Лепешка мексиканская Tortillas со',
  'вкусом сыра 276г',
  '3.85 *1.000 3.85',
  '4811229012509 Батон Для вашей семьи в/с нарез',
  '500г Слуцкий хлебозавод',
  '1.92 *1.000 1.92',
  '4814957002941 Перец горошек черный Без понтов',
  'Пряный дом 20г пакет',
  '2.30 *1.000 2.30',
  'ИТОГО К ОПЛАТЕ 65.89',
  'Банк. пл. картой: 65.89',
  'Кассир: Пинчукова Л.М. 10.06.2026 14:08:18',
  'УИ 2B08EC6FC311084007193733',
];
```

- [ ] **Step 2: Commit**

```bash
git add app/test/features/scan/prostore_ocr_fixture.dart
git commit -m "test(scan): фикстура OCR реального чека ProStore"
```

---

### Task 5: Парсер позиций `ReceiptParserImpl`

**Files:**
- Create: `app/lib/features/scan/data/receipt_parser_impl.dart`
- Test: `app/test/features/scan/data/receipt_parser_impl_test.dart`

- [ ] **Step 1: Написать падающий тест**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/data/receipt_parser_impl.dart';

import '../prostore_ocr_fixture.dart';

void main() {
  final parser = ReceiptParserImpl();

  test('извлекает 14 позиций чека ProStore', () {
    final d = parser.parse(OcrResult(lines: prostoreOcrLines, qr: '2B08...'));
    expect(d.items.length, 14);
  });

  test('сумма позиций сходится с итогом 65.89', () {
    final d = parser.parse(const OcrResult(lines: prostoreOcrLines));
    expect(d.total, 65.89);
    expect(d.itemsSum, closeTo(65.89, 0.01));
    expect(d.totalMatches, isTrue);
  });

  test('склеивает многострочные названия и парсит вес', () {
    final d = parser.parse(const OcrResult(lines: prostoreOcrLines));
    expect(d.items.first.rawName, 'Напиток Coca-Cola без сахара безалк газ 2л ПЭТ');
    final weighted = d.items.firstWhere((i) => i.rawName.startsWith('Рулет'));
    expect(weighted.qty, closeTo(0.562, 0.0001));
    expect(weighted.unitPrice, 15.77);
    expect(weighted.sum, 8.86);
  });

  test('парсит дату и пробрасывает qr', () {
    final d = parser.parse(const OcrResult(lines: prostoreOcrLines, qr: 'УИ-X'));
    expect(d.purchasedAt, DateTime(2026, 6, 10, 14, 8, 18));
    expect(d.qrRaw, 'УИ-X');
  });

  test('пустой ввод → нет позиций', () {
    final d = parser.parse(const OcrResult(lines: []));
    expect(d.items, isEmpty);
    expect(d.total, isNull);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/scan/data/receipt_parser_impl_test.dart`
Expected: FAIL (`ReceiptParserImpl` не определён).

- [ ] **Step 3: Создать `receipt_parser_impl.dart`**

```dart
/// Назначение: эвристический парсер строк OCR в ReceiptDraft (формат РБ/ProStore).
///
/// Слой: data
/// Фича: scan
/// Зависимости: domain/entities/*, domain/ocr/receipt_parser.dart.
/// Ключевые типы: ReceiptParserImpl.
library;

import '../domain/entities/ocr_result.dart';
import '../domain/entities/receipt_draft.dart';
import '../domain/ocr/receipt_parser.dart';

/// Парсер кассовых чеков: строка-цена «<цена> *<кол-во> <итог>» завершает позицию,
/// строка «<код> <название>» начинает её, прочие строки — продолжение названия.
class ReceiptParserImpl implements ReceiptParser {
  static final _price =
      RegExp(r'(\d+[.,]\d{2})\s*\*\s*(\d+[.,]\d{1,3})\s+(\d+[.,]\d{2})');
  static final _header = RegExp(r'^(?:\[[МM]\]\s*)?\d{6,}\s+(.+)$');
  static final _total =
      RegExp(r'ИТОГО\s+К\s+ОПЛАТЕ\D*(\d+[.,]\d{2})', caseSensitive: false);
  static final _dt =
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');

  double _num(String s) => double.parse(s.replaceAll(',', '.'));

  @override
  ReceiptDraft parse(OcrResult ocr) {
    final items = <ReceiptItemDraft>[];
    String? name;
    double? total;
    DateTime? purchasedAt;

    for (final raw in ocr.lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final price = _price.firstMatch(line);
      if (price != null && name != null) {
        items.add(ReceiptItemDraft(
          rawName: name.trim(),
          unitPrice: _num(price.group(1)!),
          qty: _num(price.group(2)!),
          sum: _num(price.group(3)!),
        ));
        name = null;
        continue;
      }

      final tot = _total.firstMatch(line);
      if (tot != null) {
        total = _num(tot.group(1)!);
        name = null;
        continue;
      }

      final dt = _dt.firstMatch(line);
      if (dt != null) {
        purchasedAt = DateTime(
          int.parse(dt.group(3)!), int.parse(dt.group(2)!),
          int.parse(dt.group(1)!), int.parse(dt.group(4)!),
          int.parse(dt.group(5)!), int.parse(dt.group(6)!),
        );
        continue;
      }

      final head = _header.firstMatch(line);
      if (head != null) {
        name = head.group(1)!;
        continue;
      }

      if (name != null) name = '$name $line';
    }

    return ReceiptDraft(
      items: items,
      total: total,
      purchasedAt: purchasedAt,
      qrRaw: ocr.qr,
    );
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/scan/data/receipt_parser_impl_test.dart`
Expected: PASS (5 тестов).

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/scan/data/receipt_parser_impl.dart app/test/features/scan/data/receipt_parser_impl_test.dart
git commit -m "feat(scan): парсер позиций чека (формат РБ)"
```

---

### Task 6: Сохранение чека — datasource + repository + usecase

**Files:**
- Modify: `app/lib/features/scan/data/datasources/scan_remote_datasource.dart`
- Modify: `app/lib/features/scan/data/repositories/scan_repository_impl.dart`
- Create: `app/lib/features/scan/domain/usecases/save_scanned_receipt.dart`
- Test: `app/test/features/scan/data/repositories/save_scanned_receipt_test.dart`

- [ ] **Step 1: Расширить datasource**

В `scan_remote_datasource.dart` добавить в интерфейс `ScanRemoteDataSource`:
```dart
  /// Вставляет чек и его позиции (status=done). Возвращает id чека.
  Future<String> insertReceiptWithItems(ReceiptDraft draft);
```
Импорт вверху: `import '../../domain/entities/receipt_draft.dart';` и `import '../../domain/entities/scan_source.dart';`
Реализация в `SupabaseScanRemoteDataSource`:
```dart
  @override
  Future<String> insertReceiptWithItems(ReceiptDraft draft) async {
    final receipt = await _client.from('receipts').insert({
      'source': ScanSource.ocr.dbValue,
      'qr_raw': draft.qrRaw,
      'status': 'done',
      'total': draft.total,
      'purchased_at': draft.purchasedAt?.toIso8601String(),
    }).select('id').single();
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
```

- [ ] **Step 2: Реализовать repository-метод**

В `scan_repository_impl.dart` добавить (импорт `receipt_draft.dart`):
```dart
  @override
  Future<String> saveScannedReceipt(ReceiptDraft draft) async {
    try {
      return await _ds.insertReceiptWithItems(draft);
    } catch (e) {
      throw mapScanException(e);
    }
  }
```

- [ ] **Step 3: Создать usecase**

`app/lib/features/scan/domain/usecases/save_scanned_receipt.dart`:
```dart
/// Назначение: сценарий сохранения распознанного чека.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: entities/receipt_draft.dart, repositories/scan_repository.dart.
/// Ключевые типы: SaveScannedReceipt.
library;

import '../entities/receipt_draft.dart';
import '../repositories/scan_repository.dart';

/// Сохраняет распознанный чек. Возвращает id чека.
class SaveScannedReceipt {
  const SaveScannedReceipt(this._repo);
  final ScanRepository _repo;

  Future<String> call(ReceiptDraft draft) => _repo.saveScannedReceipt(draft);
}
```

- [ ] **Step 4: Написать падающий тест репозитория**

`app/test/features/scan/data/repositories/save_scanned_receipt_test.dart`:
```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/datasources/scan_remote_datasource.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';

class _FakeDs implements ScanRemoteDataSource {
  Object? error;
  ReceiptDraft? saved;
  @override
  String get currentUserId => 'u1';
  @override
  Future<void> uploadPhoto({required String path, required Uint8List bytes}) async {}
  @override
  Future<String> insertReceipt({required String source, required String photoPath}) async => 'x';
  @override
  Future<String> insertReceiptWithItems(ReceiptDraft draft) async {
    saved = draft;
    if (error != null) throw error!;
    return 'rid-9';
  }
}

void main() {
  final draft = ReceiptDraft(items: const [
    ReceiptItemDraft(rawName: 'A', qty: 1, unitPrice: 2, sum: 2),
  ], total: 2, qrRaw: 'УИ');

  test('saveScannedReceipt передаёт draft и возвращает id', () async {
    final ds = _FakeDs();
    final id = await ScanRepositoryImpl(ds).saveScannedReceipt(draft);
    expect(id, 'rid-9');
    expect(ds.saved, same(draft));
  });

  test('ошибка → UploadFailure', () async {
    final ds = _FakeDs()..error = const PostgrestException(message: 'x');
    await expectLater(
      () => ScanRepositoryImpl(ds).saveScannedReceipt(draft),
      throwsA(isA<UploadFailure>()),
    );
  });
}
```

- [ ] **Step 5: Запустить — fail → доработать сигнатуры → pass**

Run: `cd app && flutter test test/features/scan/data/repositories/save_scanned_receipt_test.dart`
Expected: после Step 1–3 — PASS (2 теста). Если падает компиляция — проверить, что `insertReceiptWithItems` есть в интерфейсе и реализации.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/scan/data/datasources/scan_remote_datasource.dart app/lib/features/scan/data/repositories/scan_repository_impl.dart app/lib/features/scan/domain/usecases/save_scanned_receipt.dart app/test/features/scan/data/repositories/save_scanned_receipt_test.dart
git commit -m "feat(scan): сохранение чека с позициями (datasource/repo/usecase)"
```

---

### Task 7: Нативный Vision-метод + `VisionOcrEngine`

**Files:**
- Create: `app/ios/Runner/ReceiptOcr.swift`
- Modify: `app/ios/Runner/AppDelegate.swift`
- Create: `app/lib/features/scan/data/vision_ocr_engine.dart`

> Нативный модуль юнит-тестами не покрывается — проверка ручная на устройстве (Task 12).

- [ ] **Step 1: Создать `ReceiptOcr.swift`**

```swift
import Flutter
import UIKit
import Vision

/// Распознавание текста (ru) и QR чека по байтам фото через Vision.
enum ReceiptOcr {
  static func register(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "scan/ocr", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeReceipt",
            let args = call.arguments as? [String: Any],
            let data = (args["bytes"] as? FlutterStandardTypedData)?.data,
            let image = UIImage(data: data), let cg = image.cgImage else {
        result(FlutterError(code: "bad_args", message: "no image bytes", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        var lines: [(String, CGFloat)] = []
        let textReq = VNRecognizeTextRequest { req, _ in
          for obs in (req.results as? [VNRecognizedTextObservation]) ?? [] {
            if let c = obs.topCandidates(1).first {
              lines.append((c.string, obs.boundingBox.maxY))
            }
          }
        }
        textReq.recognitionLevel = .accurate
        textReq.recognitionLanguages = ["ru-RU"]
        textReq.usesLanguageCorrection = true

        var qr: String?
        let qrReq = VNDetectBarcodesRequest { req, _ in
          for obs in (req.results as? [VNBarcodeObservation]) ?? []
          where obs.symbology == .qr {
            if let p = obs.payloadStringValue { qr = p; break }
          }
        }

        let handler = VNImageRequestHandler(cgImage: cg, options: [:])
        try? handler.perform([textReq, qrReq])
        // Vision: origin внизу-слева → сортировка по maxY убыванию = сверху вниз.
        let ordered = lines.sorted { $0.1 > $1.1 }.map { $0.0 }
        DispatchQueue.main.async {
          result(["lines": ordered, "qr": qr as Any])
        }
      }
    }
  }
}
```

- [ ] **Step 2: Зарегистрировать в `AppDelegate.swift`**

В `application(_:didFinishLaunchingWithOptions:)` после `GeneratedPluginRegistrant.register(with: self)` добавить:
```swift
    if let controller = window?.rootViewController as? FlutterViewController {
      ReceiptOcr.register(controller.binaryMessenger)
    }
```

- [ ] **Step 3: Создать `vision_ocr_engine.dart`**

```dart
/// Назначение: реализация ReceiptOcrEngine поверх нативного Vision (MethodChannel).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, flutter/services, flutter_riverpod,
///   domain/entities/ocr_result.dart, domain/ocr/receipt_ocr_engine.dart.
/// Ключевые типы: VisionOcrEngine, receiptOcrEngineProvider.
library;

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ocr_result.dart';
import '../domain/ocr/receipt_ocr_engine.dart';

/// OCR поверх нативного Apple Vision (канал `scan/ocr`).
class VisionOcrEngine implements ReceiptOcrEngine {
  const VisionOcrEngine();

  static const _channel = MethodChannel('scan/ocr');

  @override
  Future<OcrResult> recognize(Uint8List photoBytes) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      'recognizeReceipt',
      {'bytes': photoBytes},
    );
    final lines = (res?['lines'] as List?)?.cast<String>() ?? const <String>[];
    return OcrResult(lines: lines, qr: res?['qr'] as String?);
  }
}

/// DI-провайдер движка OCR.
final receiptOcrEngineProvider =
    Provider<ReceiptOcrEngine>((ref) => const VisionOcrEngine());
```

- [ ] **Step 4: Проверить анализ и сборку iOS**

Run: `cd app && dart analyze lib/features/scan/data/vision_ocr_engine.dart`
Expected: No issues found.
(Сборку iOS проверяем на устройстве в Task 12.)

- [ ] **Step 5: Commit**

```bash
git add app/ios/Runner/ReceiptOcr.swift app/ios/Runner/AppDelegate.swift app/lib/features/scan/data/vision_ocr_engine.dart
git commit -m "feat(scan): нативный Vision OCR (текст ru + QR) и VisionOcrEngine"
```

---

### Task 8: Контроллер OCR-потока

**Files:**
- Modify (rewrite): `app/lib/features/scan/presentation/controllers/scan_controller.dart`
- Regenerate: `app/lib/features/scan/presentation/controllers/scan_controller.g.dart`
- Modify: `app/test/features/scan/scan_test_fakes.dart` (добавить `FakeOcrEngine`)
- Test (replace): `app/test/features/scan/presentation/controllers/scan_controller_test.dart`

- [ ] **Step 1: Добавить `FakeOcrEngine` в фейки**

В `app/test/features/scan/scan_test_fakes.dart` добавить (импорты `dart:typed_data`, `ocr_result.dart`, `receipt_ocr_engine.dart`) и расширить `FakeScanRepository` методом `saveScannedReceipt`:
```dart
// импорты добавить:
// import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
// import 'package:ticket_app/features/scan/domain/entities/receipt_draft.dart';
// import 'package:ticket_app/features/scan/domain/ocr/receipt_ocr_engine.dart';

/// Фейк движка OCR — отдаёт заранее заданный результат.
class FakeOcrEngine implements ReceiptOcrEngine {
  FakeOcrEngine(this.result);
  final OcrResult result;
  @override
  Future<OcrResult> recognize(Uint8List photoBytes) async => result;
}
```
И в `FakeScanRepository` добавить:
```dart
  ReceiptDraft? savedDraft;
  @override
  Future<String> saveScannedReceipt(ReceiptDraft draft) async {
    savedDraft = draft;
    if (error != null) throw error!;
    return receiptId;
  }
```

- [ ] **Step 2: Написать падающий тест контроллера**

Заменить `scan_controller_test.dart` целиком:
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
    photoPickerProvider.overrideWithValue(picker ?? (FakePhotoPicker()..result = kValidPngBytes)),
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
    expect((c.read(scanControllerProvider) as ScanReview).draft.items.length, 13);
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
```

- [ ] **Step 3: Переписать `scan_controller.dart` целиком**

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
final receiptParserProvider = Provider<ReceiptParser>((ref) => ReceiptParserImpl());

/// Управляет потоком: захват → OCR → парсинг → ревью → сохранение.
@riverpod
class ScanController extends _$ScanController {
  @override
  ScanState build() => const ScanIdle();

  Future<void> pickFromCamera() => _capture((p) => p.pickFromCamera());
  Future<void> pickFromGallery() => _capture((p) => p.pickFromGallery());

  Future<void> _capture(Future<Uint8List?> Function(PhotoPicker) pick) async {
    try {
      final bytes = await pick(ref.read(photoPickerProvider));
      if (bytes == null) return; // отмена
      state = const ScanRecognizing();
      final ocr = await ref.read(receiptOcrEngineProvider).recognize(bytes);
      final draft = ref.read(receiptParserProvider).parse(ocr);
      state = ScanReview(draft);
    } catch (e) {
      state = ScanError(mapScanException(e));
    }
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
      final id = await SaveScannedReceipt(ref.read(scanRepositoryProvider))(draft);
      state = ScanSaved(id);
    } catch (e) {
      state = ScanError(mapScanException(e), draft);
    }
  }

  /// Сброс к началу.
  void reset() => state = const ScanIdle();
}
```

- [ ] **Step 4: Codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: успех, обновлён `scan_controller.g.dart`.

- [ ] **Step 5: Запустить тест**

Run: `cd app && flutter test test/features/scan/presentation/controllers/scan_controller_test.dart`
Expected: PASS (6 тестов).

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/scan/presentation/controllers/scan_controller.dart app/lib/features/scan/presentation/controllers/scan_controller.g.dart app/test/features/scan/scan_test_fakes.dart app/test/features/scan/presentation/controllers/scan_controller_test.dart
git commit -m "feat(scan): контроллер OCR-потока (захват→распознавание→ревью→сохранение)"
```

---

### Task 9: Экран ревью позиций

**Files:**
- Create: `app/lib/features/scan/presentation/widgets/receipt_review_view.dart`

- [ ] **Step 1: Создать `receipt_review_view.dart`**

```dart
/// Назначение: вид ревью распознанного чека — позиции, итог, сохранить/отмена.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   domain/entities/receipt_draft.dart, presentation/controllers/scan_controller.dart.
/// Ключевые типы: ReceiptReviewView.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt_draft.dart';
import '../controllers/scan_controller.dart';

/// Список распознанных позиций с возможностью удалить строку и сохранить чек.
class ReceiptReviewView extends ConsumerWidget {
  const ReceiptReviewView({
    super.key,
    required this.draft,
    this.saving = false,
    this.error,
  });

  final ReceiptDraft draft;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(scanControllerProvider.notifier);

    return Column(
      children: [
        if (!draft.totalMatches)
          Padding(
            padding: EdgeInsets.all(tokens.spaceMd),
            child: AppBadge(
              label: 'Сумма позиций не сходится с итогом — проверьте',
              variant: AppBadgeVariant.warning,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: draft.items.length,
            itemBuilder: (context, i) {
              final it = draft.items[i];
              return Dismissible(
                key: ValueKey('item_$i\_${it.rawName}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => controller.removeItem(i),
                background: ColoredBox(color: scheme.errorContainer),
                child: AppListTile(
                  title: it.rawName,
                  subtitle: '${it.qty} × ${it.unitPrice}',
                  trailing: MoneyText(amount: it.sum),
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
                  MoneyText(amount: draft.total ?? draft.itemsSum),
                ],
              ),
              if (error != null) ...[
                SizedBox(height: tokens.spaceSm),
                Text(error!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error)),
              ],
              SizedBox(height: tokens.spaceLg),
              AppButton(
                label: 'Сохранить',
                icon: Icons.save_alt,
                expanded: true,
                loading: saving,
                onPressed: saving ? null : controller.save,
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

- [ ] **Step 2: Проверить анализ**

Run: `cd app && dart analyze lib/features/scan/presentation/widgets/receipt_review_view.dart`
Expected: No issues found. Если `MoneyText`/`AppBadge`/`AppBadgeVariant`/`AppListTile` имеют другую сигнатуру — открыть `app/lib/shared/components/components.dart` и привести вызовы к фактическому API (поля компонентов смотреть в соответствующих файлах `app/lib/shared/components/`).

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/scan/presentation/widgets/receipt_review_view.dart
git commit -m "feat(scan): экран-вид ревью распознанных позиций"
```

---

### Task 10: Экран скана и widget-тест

**Files:**
- Modify (rewrite): `app/lib/features/scan/presentation/screens/scan_screen.dart`
- Test (replace): `app/test/features/scan/presentation/screens/scan_screen_test.dart`

- [ ] **Step 1: Переписать `scan_screen.dart`**

```dart
/// Назначение: экран «Скан» — захват фото → распознавание → ревью → сохранение.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components,
///   presentation/controllers/scan_controller.dart, presentation/widgets/*.
/// Ключевые типы: ScanScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';
import '../widgets/receipt_review_view.dart';
import '../widgets/scan_capture_view.dart';

/// Экран скана чека (фото → OCR → позиции).
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);

    final body = switch (state) {
      ScanIdle() => const ScanCaptureView(),
      ScanError(:final draft) when draft == null =>
        ScanCaptureView(error: state.failure.message),
      ScanRecognizing() => const AppLoader(),
      ScanReview(:final draft) => ReceiptReviewView(draft: draft),
      ScanSaving(:final draft) => ReceiptReviewView(draft: draft, saving: true),
      ScanError(:final draft) =>
        ReceiptReviewView(draft: draft!, error: state.failure.message),
      ScanSaved() => _SavedView(),
    };

    return AppScaffold(title: 'Сканировать', body: body);
  }
}

class _SavedView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(scanControllerProvider.notifier);
    return Padding(
      padding: EdgeInsets.all(context.tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppEmptyState(
            message: 'Чек сохранён.',
            icon: Icons.check_circle_outline,
          ),
          SizedBox(height: context.tokens.spaceXl),
          AppButton(
            label: 'Сканировать ещё',
            icon: Icons.add_a_photo,
            expanded: true,
            onPressed: controller.reset,
          ),
        ],
      ),
    );
  }
}
```
(Импорт `context.tokens` приходит через `components.dart`? Если нет — добавить `import '../../../../core/theme/app_tokens.dart';`.)

- [ ] **Step 2: Заменить widget-тест**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/data/vision_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';

import '../../prostore_ocr_fixture.dart';
import '../../scan_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('захват → ревью позиций → сохранение', (tester) async {
    await pumpApp(
      tester,
      const ScanScreen(),
      overrides: [
        photoPickerProvider.overrideWithValue(FakePhotoPicker()..result = kValidPngBytes),
        receiptOcrEngineProvider.overrideWithValue(
            FakeOcrEngine(const OcrResult(lines: prostoreOcrLines, qr: 'УИ'))),
        scanRepositoryProvider.overrideWithValue(FakeScanRepository()),
      ],
    );

    expect(find.text('Сфотографировать'), findsOneWidget);
    await tester.tap(find.text('Сфотографировать'));
    await tester.pumpAndSettle();

    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сканировать ещё'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Запустить тест**

Run: `cd app && flutter test test/features/scan/presentation/screens/scan_screen_test.dart`
Expected: PASS. (Список из 14 позиций может потребовать прокрутки; тест проверяет нижнюю панель «Итого»/«Сохранить», которая вне `ListView`.)

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/scan/presentation/screens/scan_screen.dart app/test/features/scan/presentation/screens/scan_screen_test.dart
git commit -m "feat(scan): экран скана с ревью и сохранением"
```

---

### Task 11: Удалить устаревший путь «фото→Storage→pending»

**Files:**
- Delete: `app/lib/features/scan/data/image_compressor.dart`
- Delete: `app/lib/features/scan/presentation/widgets/scan_preview_view.dart`
- Delete: `app/lib/features/scan/presentation/widgets/scan_success_view.dart`
- Delete: `app/test/features/scan/data/image_compressor_test.dart`
- Delete: `app/test/features/scan/data/repositories/scan_repository_impl_test.dart`
- Modify: `app/lib/features/scan/data/datasources/scan_remote_datasource.dart`
- Modify: `app/lib/features/scan/data/repositories/scan_repository_impl.dart`
- Modify: `app/lib/features/scan/domain/repositories/scan_repository.dart`

- [ ] **Step 1: Удалить файлы устаревшего пути**

```bash
cd /Users/pablo/work/receipt-scan-app
git rm app/lib/features/scan/data/image_compressor.dart \
       app/lib/features/scan/presentation/widgets/scan_preview_view.dart \
       app/lib/features/scan/presentation/widgets/scan_success_view.dart \
       app/test/features/scan/data/image_compressor_test.dart \
       app/test/features/scan/data/repositories/scan_repository_impl_test.dart
```

- [ ] **Step 2: Убрать `createReceiptFromPhoto` из домена**

В `app/lib/features/scan/domain/repositories/scan_repository.dart` удалить метод
`Future<String> createReceiptFromPhoto(Uint8List photoBytes);` и, если `dart:typed_data`
больше не используется в файле, убрать его импорт. Оставить `saveScannedReceipt`.

- [ ] **Step 3: Убрать реализацию и неиспользуемые методы datasource/repo**

В `scan_repository_impl.dart` удалить метод `createReceiptFromPhoto(...)` и импорт
`../image_compressor.dart`. Оставить `saveScannedReceipt`.
В `scan_remote_datasource.dart` удалить методы `uploadPhoto(...)` и
`insertReceipt(...)` из интерфейса и реализации (их использовал только старый путь),
удалить `currentUserId`, если он больше нигде не нужен. Оставить `insertReceiptWithItems`.
В тесте `save_scanned_receipt_test.dart` (Task 6) у `_FakeDs` убрать переопределения
удалённых методов, чтобы он реализовывал только актуальный интерфейс.

- [ ] **Step 4: Полный анализ и тесты**

Run: `cd app && dart analyze && flutter test`
Expected: `No issues found.` и все тесты PASS (старые тесты удалены, новые зелёные).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor(scan): убрать устаревший путь фото→Storage→pending"
```

---

### Task 12: Документация и ручная проверка на устройстве

**Files:**
- Modify: `docs/features/scan.md`
- Modify: `docs/architecture/data-model.md`

- [ ] **Step 1: Обновить `docs/features/scan.md`**

В раздел «Реализовано» добавить:
```markdown
## Реализовано (цикл 2026-06-14 — Фаза 1)
- iOS: фото чека (камера/галерея) → Apple Vision (текст ru + QR) → парсер позиций →
  экран-ревью (удаление строки свайпом) → сохранение `receipts`+`receipt_items` (status=done).
- УИ из QR сохраняется в `receipts.qr_raw`; валюта проставляется триггером из страны.
- Источник позиций — OCR по фото (легального API «позиции по QR» в РБ нет; обоснование —
  в спеке 2026-06-14).

## Отложено
- Фаза 2: живое AVFoundation-превью с real-time QR-оверлеем.
- Редактирование полей позиций (сейчас только удаление строки).
- LLM-движок OCR (будущая платная фича), Android-движок.
```

- [ ] **Step 2: Обновить `docs/architecture/data-model.md`**

В строку `receipt_items` зоны A добавить сноску под таблицей зоны A:
```markdown
> `receipt_items` создаётся миграцией `0003`; `product_id` без FK (products зоны B ещё
> нет). Заполняется клиентским OCR-путём (insert при сохранении скана). `receipts.currency`
> проставляется триггером `receipts_fill_owner` из `country_code` (BY→BYN, RU→RUB, KZ→KZT).
```

- [ ] **Step 3: Ручная проверка на реальном iPhone**

Собрать на устройстве (`cd app && ./run-dev.sh <device-id>`; список — `flutter devices`).
Войти → вкладка «Скан» → «Сфотографировать»/«Из галереи» → выбрать чек ProStore →
дождаться распознавания → проверить список позиций и итог → «Сохранить».
Затем supabase MCP `execute_sql`:
```sql
select r.id, r.status, r.currency, r.qr_raw,
       (select count(*) from public.receipt_items i where i.receipt_id = r.id) as items
from public.receipts r where r.source='ocr' order by r.created_at desc limit 1;
```
Ожидаем `status='done'`, `currency='BYN'`, заполненный `qr_raw`, `items > 0`.
> Симулятор не подойдёт: камера и Apple Vision требуют реального устройства.

- [ ] **Step 4: Commit**

```bash
git add docs/features/scan.md docs/architecture/data-model.md
git commit -m "docs(scan): актуализация фичи scan и data-model (OCR-позиции)"
```

---

## Self-Review

**1. Покрытие спека:**
- §2 объём (фото→OCR→парсер→ревью→сохранить, iOS) → Tasks 2–10. ✅
- §4.1 нативный Vision (текст ru + QR) → Task 7. ✅
- §4.2 контракты движка/парсера, usecase, datasource, repo, контроллер, экраны → Tasks 3,5,6,8,9,10. ✅
- §5 парсер (формат РБ, склейка, итог/дата, сверка) → Task 5 (+фикстура Task 4). ✅
- §6 миграция receipt_items + RLS + currency, сохранение без Storage/pgmq, privacy-review → Task 1, Task 6. ✅
- §3 ревью read-only + свайп-удаление, Save/Cancel → Task 8 (removeItem), Task 9. ✅
- §8 ошибки (камера/QR-нет/OCR-пусто/сохранение) → mapScanException + состояния (Task 8), QR null допустим (parser/draft). ✅
- §9 тесты (парсер на реальном чеке, usecase/контроллер/datasource фейки, виджет ревью, ручная на устройстве) → Tasks 5,6,8,10,12. ✅
- §10 риски (точность, длинный чек, только устройство) → отражены в Task 12 и плане. ✅
- Живая камера (Flow A, §4.1 превью) → **вынесено в Фазу 2** (отдельный план) — осознанно, заявлено в Goal/Architecture.

**2. Плейсхолдеры:** нет — у каждого шага конкретный код/команда/ожидаемый вывод.

**3. Согласованность типов:** `ReceiptOcrEngine.recognize(Uint8List)`, `ReceiptParser.parse(OcrResult)→ReceiptDraft`, `ScanRepository.saveScannedReceipt(ReceiptDraft)`, `ScanRemoteDataSource.insertReceiptWithItems(ReceiptDraft)`, провайдеры `receiptOcrEngineProvider`/`receiptParserProvider`/`scanRepositoryProvider`/`photoPickerProvider`, состояния `ScanIdle/ScanRecognizing/ScanReview/ScanSaving/ScanSaved/ScanError` — имена едины во всех задачах. `ScanCaptureView` (оставлен от прошлого цикла) переиспользуется в Task 10.

**Замечание по спеку:** §4.2 упоминал `OcrLine(text, top, …)`; реализация использует упорядоченный `List<String>` (нативный модуль сортирует строки сверху вниз) — упрощение без потери смысла, координаты не нужны парсеру.
