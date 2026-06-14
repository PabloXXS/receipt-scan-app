# Receipts List Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Реализовать экран списка чеков (пагинация по 25, свайп-удаление) и экран деталей чека, с таблицей-справочником `stores` для названий магазинов.

**Architecture:** Трёхслойная фича `receipts` (data/domain/presentation) по образцу `features/scan`. Riverpod codegen (`@riverpod`). Пагинация — рукописный `AsyncNotifier` с состоянием `items + hasMore + isLoadingMore`, offset-based по `created_at desc`. Удаление — `flutter_slidable` + диалог подтверждения, после удаления — полный refetch. Название магазина — join `stores(name)` через PostgREST-эмбед (новая таблица зоны B + FK).

**Tech Stack:** Flutter, flutter_riverpod + riverpod_annotation (codegen), go_router, supabase_flutter, flutter_slidable ^3.0.1, intl. Тесты — flutter_test + ProviderContainer/pumpApp. БД — Supabase Postgres + RLS.

**Спецификация:** `docs/superpowers/specs/2026-06-14-receipts-list-screen-design.md`

**Общие правила проекта (соблюдать в каждом файле):**
- Пакет импорта: `package:ticket_app/...`.
- Каждый новый файл кода — с шапкой-документацией (`Назначение / Слой / Фича / Зависимости / Ключевые типы`) по `docs/conventions/documentation.md`.
- Доменные сущности — обычные immutable-классы (НЕ freezed), как в `features/scan/domain`.
- После создания `@riverpod`-провайдеров (part-файлы `*.g.dart`) запускать кодоген:
  `cd app && dart run build_runner build --delete-conflicting-outputs`.
- Команды запуска из каталога `app/`.
- `dart format` выполняется хуком автоматически после правок — отдельный шаг не нужен.

---

## Структура файлов

**Создать:**
- `supabase/migrations/0004_stores_chains.sql` — справочник зоны B + FK.
- `app/lib/features/receipts/domain/entities/receipt_status.dart` — enum статуса.
- `app/lib/features/receipts/domain/entities/receipt.dart` — сущность строки списка.
- `app/lib/features/receipts/domain/entities/receipt_item.dart` — позиция чека.
- `app/lib/features/receipts/domain/entities/receipt_details.dart` — чек + позиции.
- `app/lib/features/receipts/domain/repositories/receipts_repository.dart` — контракт.
- `app/lib/features/receipts/data/receipts_error_mapper.dart` — маппинг исключений.
- `app/lib/features/receipts/data/models/receipt_dto.dart` — маппинг строк PostgREST.
- `app/lib/features/receipts/data/datasources/receipts_remote_datasource.dart` — Supabase.
- `app/lib/features/receipts/data/repositories/receipts_repository_impl.dart` — реализация + DI.
- `app/lib/features/receipts/presentation/controllers/receipts_list_controller.dart` — список/пагинация.
- `app/lib/features/receipts/presentation/controllers/receipt_details_controller.dart` — детали.
- `app/lib/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart` — миниатюра фото.
- `app/lib/features/receipts/presentation/widgets/receipt_status_badge.dart` — бейдж статуса.
- `app/lib/features/receipts/presentation/widgets/receipt_list_item.dart` — строка списка (slidable).
- `app/lib/features/receipts/presentation/screens/receipt_details_screen.dart` — экран деталей.
- `docs/adr/0002-receipts-pagination.md` — ADR про пагинацию.
- Тест-фейки и тесты под `app/test/features/receipts/**`.

**Изменить:**
- `app/lib/core/error/failure.dart` — добавить семейство `ReceiptsFailure`.
- `app/lib/features/receipts/presentation/screens/receipts_screen.dart` — заменить заглушку.
- `app/lib/core/router/app_routes.dart` — путь деталей.
- `app/lib/core/router/app_router.dart` — вложенный маршрут деталей.
- `app/test/features/receipts/presentation/screens/receipts_screen_test.dart` — переписать.
- `docs/features/receipts.md`, `docs/architecture/data-model.md` — живая документация.

---

## Task 1: Миграция БД — справочник `stores`/`chains` (зона B) + FK

**Files:**
- Create: `supabase/migrations/0004_stores_chains.sql`

- [ ] **Step 1: Создать файл миграции**

Можно через скилл `/supabase-migration stores_chains` (он подставит RLS-каркас зоны B), затем заменить тело на SQL ниже. Содержимое файла:

```sql
-- Миграция: reference — справочник торговых сетей и точек (зона B) + FK на receipts.
-- Зона доступа: B (общий справочник). RLS: select всем authenticated; insert/update — service-role (воркер).
-- Инвариант приватности: зона B, БЕЗ user_id/family_id (в зону C ничего не уходит).

create table if not exists public.chains (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  country_code text not null,
  created_at   timestamptz not null default now()
);

create table if not exists public.stores (
  id           uuid primary key default gen_random_uuid(),
  chain_id     uuid references public.chains (id) on delete set null,
  name         text not null,
  address      text,
  lat          double precision,
  lng          double precision,
  region       text,
  country_code text not null,
  created_at   timestamptz not null default now()
);

create index if not exists stores_chain_id_idx on public.stores (chain_id);
create index if not exists stores_country_code_idx on public.stores (country_code);

-- FK receipts.store_id → stores.id (создавался без FK в 0002). on delete set null:
-- удаление точки справочника не должно удалять чеки пользователя.
alter table public.receipts
  drop constraint if exists receipts_store_id_fkey;
alter table public.receipts
  add constraint receipts_store_id_fkey
  foreign key (store_id) references public.stores (id) on delete set null;

-- RLS зоны B: чтение всем авторизованным; запись — только service-role (минует RLS),
-- клиентских политик insert/update/delete НЕ создаём.
alter table public.chains enable row level security;
alter table public.stores enable row level security;

drop policy if exists "chains_select_all_auth" on public.chains;
create policy "chains_select_all_auth"
  on public.chains for select to authenticated using (true);

drop policy if exists "stores_select_all_auth" on public.stores;
create policy "stores_select_all_auth"
  on public.stores for select to authenticated using (true);
```

- [ ] **Step 2: Проверить миграцию субагентом приватности**

Запустить субагент `privacy-rls-reviewer` на изменении `supabase/migrations/0004_stores_chains.sql`.
Ожидаемо: подтверждение, что `stores`/`chains` — зона B без `user_id`/`family_id`, FK безопасен (`on delete set null`), RLS-политики чтения корректны и нет клиентской записи. Исправить замечания, если будут.

- [ ] **Step 3: Применить миграцию к dev-проекту**

Применить через Supabase MCP `apply_migration` (name: `0004_stores_chains`, query — содержимое файла) к dev-проекту CheckPrices (`yftrsgcqrzzmxbttlltz`). Затем проверить через MCP `list_tables`, что таблицы `public.stores` и `public.chains` существуют и у `receipts` появился constraint `receipts_store_id_fkey`.
Ожидаемо: обе таблицы присутствуют, FK создан.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/0004_stores_chains.sql
git commit -m "feat(receipts): миграция stores/chains (зона B) + FK receipts.store_id"
```

---

## Task 2: Enum `ReceiptStatus`

**Files:**
- Create: `app/lib/features/receipts/domain/entities/receipt_status.dart`
- Test: `app/test/features/receipts/domain/entities/receipt_status_test.dart`

- [ ] **Step 1: Написать падающий тест**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  test('fromDb мапит значения колонки receipts.status', () {
    expect(ReceiptStatus.fromDb('pending'), ReceiptStatus.pending);
    expect(ReceiptStatus.fromDb('processing'), ReceiptStatus.processing);
    expect(ReceiptStatus.fromDb('done'), ReceiptStatus.done);
    expect(ReceiptStatus.fromDb('failed'), ReceiptStatus.failed);
  });

  test('неизвестное значение → pending (безопасный дефолт)', () {
    expect(ReceiptStatus.fromDb('whatever'), ReceiptStatus.pending);
  });

  test('у каждого статуса есть непустой label', () {
    for (final s in ReceiptStatus.values) {
      expect(s.label, isNotEmpty);
    }
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/domain/entities/receipt_status_test.dart`
Expected: FAIL (target of URI doesn't exist / ReceiptStatus не определён).

- [ ] **Step 3: Реализовать enum**

```dart
/// Назначение: статус обработки чека (значения колонки `receipts.status`).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: нет.
/// Ключевые типы: ReceiptStatus.
library;

/// Статус чека в пайплайне обработки.
enum ReceiptStatus {
  /// В очереди на обработку.
  pending('В очереди'),

  /// Обрабатывается воркером.
  processing('Обработка'),

  /// Обработан успешно.
  done('Готово'),

  /// Обработка завершилась ошибкой.
  failed('Ошибка');

  const ReceiptStatus(this.label);

  /// Человекочитаемая подпись для бейджа.
  final String label;

  /// Маппинг из значения колонки `receipts.status`. Неизвестное → [pending].
  static ReceiptStatus fromDb(String? value) => switch (value) {
        'processing' => ReceiptStatus.processing,
        'done' => ReceiptStatus.done,
        'failed' => ReceiptStatus.failed,
        _ => ReceiptStatus.pending,
      };
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/domain/entities/receipt_status_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/domain/entities/receipt_status.dart app/test/features/receipts/domain/entities/receipt_status_test.dart
git commit -m "feat(receipts): enum ReceiptStatus с маппингом из БД"
```

---

## Task 3: Доменные сущности `Receipt`, `ReceiptItem`, `ReceiptDetails`

**Files:**
- Create: `app/lib/features/receipts/domain/entities/receipt.dart`
- Create: `app/lib/features/receipts/domain/entities/receipt_item.dart`
- Create: `app/lib/features/receipts/domain/entities/receipt_details.dart`
- Test: `app/test/features/receipts/domain/entities/receipt_test.dart`

- [ ] **Step 1: Написать падающий тест**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_details.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_item.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  final createdAt = DateTime.utc(2026, 6, 14, 10);

  test('Receipt хранит переданные поля', () {
    final r = Receipt(
      id: 'r1',
      storeName: 'Пятёрочка',
      total: 123.45,
      currency: 'RUB',
      status: ReceiptStatus.done,
      purchasedAt: createdAt,
      createdAt: createdAt,
      photoPath: 'uid/r1.jpg',
    );
    expect(r.id, 'r1');
    expect(r.storeName, 'Пятёрочка');
    expect(r.total, 123.45);
    expect(r.status, ReceiptStatus.done);
  });

  test('ReceiptDetails объединяет чек и позиции', () {
    final r = Receipt(
      id: 'r1',
      status: ReceiptStatus.done,
      createdAt: createdAt,
    );
    const item = ReceiptItem(id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80);
    final d = ReceiptDetails(receipt: r, items: [item]);
    expect(d.receipt.id, 'r1');
    expect(d.items.single.rawName, 'Молоко');
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/domain/entities/receipt_test.dart`
Expected: FAIL (классы не определены).

- [ ] **Step 3: Реализовать `receipt_item.dart`**

```dart
/// Назначение: позиция чека для экрана деталей.
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: нет.
/// Ключевые типы: ReceiptItem.
library;

/// Одна позиция чека (`receipt_items`).
class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.rawName,
    required this.qty,
    required this.unitPrice,
    required this.sum,
  });

  final String id;
  final String rawName;
  final double qty;
  final double unitPrice;
  final double sum;
}
```

- [ ] **Step 4: Реализовать `receipt.dart`**

```dart
/// Назначение: чек для строки списка (`receipts` + join `stores.name`).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: receipt_status.dart.
/// Ключевые типы: Receipt.
library;

import 'receipt_status.dart';

/// Чек в списке: магазин, сумма, дата, статус, путь к фото.
class Receipt {
  const Receipt({
    required this.id,
    required this.status,
    required this.createdAt,
    this.storeId,
    this.storeName,
    this.total,
    this.currency,
    this.purchasedAt,
    this.photoPath,
  });

  final String id;
  final ReceiptStatus status;
  final DateTime createdAt;
  final String? storeId;

  /// Название магазина из справочника `stores`; null — ещё не распознан.
  final String? storeName;
  final double? total;
  final String? currency;
  final DateTime? purchasedAt;

  /// Путь объекта в приватном бакете `receipts` (нужен signed URL).
  final String? photoPath;
}
```

- [ ] **Step 5: Реализовать `receipt_details.dart`**

```dart
/// Назначение: детали чека — сам чек и его позиции.
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: receipt.dart, receipt_item.dart.
/// Ключевые типы: ReceiptDetails.
library;

import 'receipt.dart';
import 'receipt_item.dart';

/// Чек со списком позиций для экрана деталей.
class ReceiptDetails {
  const ReceiptDetails({required this.receipt, required this.items});

  final Receipt receipt;
  final List<ReceiptItem> items;
}
```

- [ ] **Step 6: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/domain/entities/receipt_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/lib/features/receipts/domain/entities/ app/test/features/receipts/domain/entities/receipt_test.dart
git commit -m "feat(receipts): доменные сущности Receipt/ReceiptItem/ReceiptDetails"
```

---

## Task 4: Контракт репозитория + ошибки `ReceiptsFailure` + mapper

**Files:**
- Modify: `app/lib/core/error/failure.dart` (добавить семейство ошибок в конец файла)
- Create: `app/lib/features/receipts/domain/repositories/receipts_repository.dart`
- Create: `app/lib/features/receipts/data/receipts_error_mapper.dart`
- Test: `app/test/features/receipts/data/receipts_error_mapper_test.dart`

- [ ] **Step 1: Написать падающий тест на mapper**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/receipts_error_mapper.dart';

void main() {
  test('SocketException → ReceiptsNetworkFailure', () {
    expect(mapReceiptsException(const SocketException('x')),
        isA<ReceiptsNetworkFailure>());
  });

  test('PostgrestException → ReceiptsLoadFailure', () {
    expect(
      mapReceiptsException(const PostgrestException(message: 'boom')),
      isA<ReceiptsLoadFailure>(),
    );
  });

  test('готовый ReceiptsFailure возвращается как есть', () {
    const f = ReceiptsDeleteFailure();
    expect(mapReceiptsException(f), same(f));
  });

  test('прочее → UnknownReceiptsFailure', () {
    expect(mapReceiptsException(Exception('x')), isA<UnknownReceiptsFailure>());
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/data/receipts_error_mapper_test.dart`
Expected: FAIL (типы/функция не определены).

- [ ] **Step 3: Добавить семейство ошибок в `failure.dart`**

Добавить в конец файла `app/lib/core/error/failure.dart` (после `UnknownScanFailure`):

```dart
/// Базовая ошибка работы со списком/деталями чеков (показывается `message`).
sealed class ReceiptsFailure extends Failure {
  const ReceiptsFailure(super.message);
}

/// Нет соединения с сервером при загрузке чеков.
class ReceiptsNetworkFailure extends ReceiptsFailure {
  const ReceiptsNetworkFailure([super.message = 'Нет соединения с сервером']);
}

/// Не удалось загрузить чеки.
class ReceiptsLoadFailure extends ReceiptsFailure {
  const ReceiptsLoadFailure([
    super.message = 'Не удалось загрузить чеки. Попробуйте ещё раз.',
  ]);
}

/// Не удалось удалить чек.
class ReceiptsDeleteFailure extends ReceiptsFailure {
  const ReceiptsDeleteFailure([
    super.message = 'Не удалось удалить чек. Попробуйте ещё раз.',
  ]);
}

/// Непредвиденная ошибка при работе с чеками.
class UnknownReceiptsFailure extends ReceiptsFailure {
  const UnknownReceiptsFailure([super.message = 'Не удалось обработать запрос']);
}
```

- [ ] **Step 4: Реализовать контракт репозитория**

Создать `app/lib/features/receipts/domain/repositories/receipts_repository.dart`:

```dart
/// Назначение: контракт доступа к чекам (список, детали, удаление, фото).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: domain/entities (receipt.dart, receipt_details.dart).
/// Ключевые типы: ReceiptsRepository.
library;

import '../entities/receipt.dart';
import '../entities/receipt_details.dart';

/// Сценарии работы со списком и деталями чеков. Реализация — в слое data.
abstract interface class ReceiptsRepository {
  /// Страница чеков, отсортированных по `created_at desc`.
  Future<List<Receipt>> list({required int limit, required int offset});

  /// Детали чека с позициями.
  Future<ReceiptDetails> getById(String id);

  /// Удаляет чек владельца.
  Future<void> delete(String id);

  /// Signed URL фото чека из приватного бакета; null — если фото нет.
  Future<String?> photoUrl(String path);
}
```

- [ ] **Step 5: Реализовать mapper**

Создать `app/lib/features/receipts/data/receipts_error_mapper.dart`:

```dart
/// Назначение: перевод исключений Supabase/сети в ReceiptsFailure.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: dart:io, supabase_flutter, core/error/failure.dart.
/// Ключевые типы: mapReceiptsException.
library;

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Преобразует [error] в [ReceiptsFailure]. Готовый [ReceiptsFailure] — как есть.
ReceiptsFailure mapReceiptsException(Object error) {
  if (error is ReceiptsFailure) return error;
  if (error is SocketException) return const ReceiptsNetworkFailure();
  if (error is StorageException) return const ReceiptsLoadFailure();
  if (error is PostgrestException) return const ReceiptsLoadFailure();
  return const UnknownReceiptsFailure();
}
```

- [ ] **Step 6: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/data/receipts_error_mapper_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/lib/core/error/failure.dart app/lib/features/receipts/domain/repositories/ app/lib/features/receipts/data/receipts_error_mapper.dart app/test/features/receipts/data/receipts_error_mapper_test.dart
git commit -m "feat(receipts): контракт ReceiptsRepository + ошибки ReceiptsFailure"
```

---

## Task 5: DTO-маппинг строк PostgREST → `Receipt` / `ReceiptDetails`

**Files:**
- Create: `app/lib/features/receipts/data/models/receipt_dto.dart`
- Test: `app/test/features/receipts/data/models/receipt_dto_test.dart`

- [ ] **Step 1: Написать падающий тест**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/models/receipt_dto.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';

void main() {
  test('receiptFromRow читает поля и эмбед stores(name)', () {
    final r = receiptFromRow({
      'id': 'r1',
      'store_id': 's1',
      'stores': {'name': 'Пятёрочка'},
      'total': '123.45',
      'currency': 'RUB',
      'status': 'done',
      'purchased_at': '2026-06-14T10:00:00Z',
      'created_at': '2026-06-14T10:05:00Z',
      'photo_path': 'uid/r1.jpg',
    });
    expect(r.id, 'r1');
    expect(r.storeName, 'Пятёрочка');
    expect(r.total, 123.45);
    expect(r.currency, 'RUB');
    expect(r.status, ReceiptStatus.done);
    expect(r.photoPath, 'uid/r1.jpg');
  });

  test('receiptFromRow без stores и total → null-поля, статус-дефолт', () {
    final r = receiptFromRow({
      'id': 'r2',
      'store_id': null,
      'stores': null,
      'total': null,
      'currency': null,
      'status': null,
      'purchased_at': null,
      'created_at': '2026-06-14T10:05:00Z',
      'photo_path': null,
    });
    expect(r.storeName, isNull);
    expect(r.total, isNull);
    expect(r.status, ReceiptStatus.pending);
  });

  test('receiptItemFromRow парсит числовые поля из строк/чисел', () {
    final it = receiptItemFromRow({
      'id': 'i1',
      'raw_name': 'Молоко',
      'qty': 2,
      'unit_price': '80.5',
      'sum': 161,
    });
    expect(it.rawName, 'Молоко');
    expect(it.qty, 2);
    expect(it.unitPrice, 80.5);
    expect(it.sum, 161);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/data/models/receipt_dto_test.dart`
Expected: FAIL (функции не определены).

- [ ] **Step 3: Реализовать DTO-маппинг**

Создать `app/lib/features/receipts/data/models/receipt_dto.dart`:

```dart
/// Назначение: маппинг строк PostgREST в доменные Receipt/ReceiptItem.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: domain/entities (receipt.dart, receipt_item.dart, receipt_status.dart).
/// Ключевые типы: receiptFromRow, receiptItemFromRow, kReceiptColumns.
library;

import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_item.dart';
import '../../domain/entities/receipt_status.dart';

/// Колонки чека для select списка (+ эмбед названия магазина).
const String kReceiptColumns =
    'id, store_id, total, currency, status, purchased_at, created_at, '
    'photo_path, stores(name)';

/// Колонки позиции чека.
const String kReceiptItemColumns = 'id, raw_name, qty, unit_price, sum';

/// numeric из PostgREST может прийти как num или String — приводим к double.
double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _toDate(Object? v) =>
    v == null ? null : DateTime.parse(v.toString()).toLocal();

/// Строка `receipts` (с эмбедом `stores(name)`) → [Receipt].
Receipt receiptFromRow(Map<String, dynamic> row) {
  final store = row['stores'];
  final storeName = store is Map ? store['name'] as String? : null;
  return Receipt(
    id: row['id'] as String,
    storeId: row['store_id'] as String?,
    storeName: storeName,
    total: _toDouble(row['total']),
    currency: row['currency'] as String?,
    status: ReceiptStatus.fromDb(row['status'] as String?),
    purchasedAt: _toDate(row['purchased_at']),
    createdAt: _toDate(row['created_at'])!,
    photoPath: row['photo_path'] as String?,
  );
}

/// Строка `receipt_items` → [ReceiptItem].
ReceiptItem receiptItemFromRow(Map<String, dynamic> row) => ReceiptItem(
      id: row['id'] as String,
      rawName: row['raw_name'] as String? ?? '',
      qty: _toDouble(row['qty']) ?? 0,
      unitPrice: _toDouble(row['unit_price']) ?? 0,
      sum: _toDouble(row['sum']) ?? 0,
    );
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/data/models/receipt_dto_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/data/models/ app/test/features/receipts/data/models/receipt_dto_test.dart
git commit -m "feat(receipts): DTO-маппинг строк PostgREST в доменные сущности"
```

---

## Task 6: Remote datasource (Supabase) + DI

**Files:**
- Create: `app/lib/features/receipts/data/datasources/receipts_remote_datasource.dart`

Примечание: чистая логика уже покрыта в Task 5 (маппинг) и будет покрыта в Task 7 (репозиторий с фейк-datasource). Datasource — тонкая обёртка над `SupabaseClient`, его не юнит-тестируем (требует живой Supabase); проверяется в ручной верификации в конце.

- [ ] **Step 1: Реализовать datasource**

Создать `app/lib/features/receipts/data/datasources/receipts_remote_datasource.dart`:

```dart
/// Назначение: доступ к receipts/receipt_items и Storage для списка/деталей/удаления.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: flutter_riverpod, supabase_flutter, core/supabase/supabase_providers.dart,
///   models/receipt_dto.dart, domain/entities.
/// Ключевые типы: ReceiptsRemoteDataSource, SupabaseReceiptsRemoteDataSource,
///   receiptsRemoteDataSourceProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_providers.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_details.dart';
import '../models/receipt_dto.dart';

/// Абстракция удалённых операций со списком/деталями чеков.
abstract interface class ReceiptsRemoteDataSource {
  Future<List<Receipt>> fetchPage({required int limit, required int offset});
  Future<ReceiptDetails> fetchById(String id);
  Future<void> deleteById(String id);
  Future<String?> createPhotoUrl(String path);
}

/// Реализация поверх Supabase PostgREST + Storage.
class SupabaseReceiptsRemoteDataSource implements ReceiptsRemoteDataSource {
  const SupabaseReceiptsRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const String _bucket = 'receipts';

  @override
  Future<List<Receipt>> fetchPage({
    required int limit,
    required int offset,
  }) async {
    final rows = await _client
        .from('receipts')
        .select(kReceiptColumns)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return rows.map((r) => receiptFromRow(r)).toList();
  }

  @override
  Future<ReceiptDetails> fetchById(String id) async {
    final row = await _client
        .from('receipts')
        .select(kReceiptColumns)
        .eq('id', id)
        .single();
    final itemRows = await _client
        .from('receipt_items')
        .select(kReceiptItemColumns)
        .eq('receipt_id', id)
        .order('created_at', ascending: true);
    return ReceiptDetails(
      receipt: receiptFromRow(row),
      items: itemRows.map((r) => receiptItemFromRow(r)).toList(),
    );
  }

  @override
  Future<void> deleteById(String id) async {
    await _client.from('receipts').delete().eq('id', id);
  }

  @override
  Future<String?> createPhotoUrl(String path) async {
    return _client.storage.from(_bucket).createSignedUrl(path, 3600);
  }
}

/// DI-провайдер источника данных чеков.
final receiptsRemoteDataSourceProvider = Provider<ReceiptsRemoteDataSource>(
  (ref) => SupabaseReceiptsRemoteDataSource(ref.watch(supabaseClientProvider)),
);
```

- [ ] **Step 2: Проверить компиляцию через анализатор**

Run: `cd app && dart analyze lib/features/receipts/data/datasources/receipts_remote_datasource.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/receipts/data/datasources/
git commit -m "feat(receipts): Supabase remote datasource (страница/детали/удаление/фото)"
```

---

## Task 7: Репозиторий-реализация + DI

**Files:**
- Create: `app/lib/features/receipts/data/repositories/receipts_repository_impl.dart`
- Test: `app/test/features/receipts/data/repositories/receipts_repository_impl_test.dart`
- Create (фейк): `app/test/features/receipts/receipts_test_fakes.dart`

- [ ] **Step 1: Создать фейки для тестов**

Создать `app/test/features/receipts/receipts_test_fakes.dart`:

```dart
import 'dart:math' as math;

import 'package:ticket_app/features/receipts/domain/entities/receipt.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_details.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_item.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt_status.dart';
import 'package:ticket_app/features/receipts/data/datasources/receipts_remote_datasource.dart';
import 'package:ticket_app/features/receipts/domain/repositories/receipts_repository.dart';

/// Удобный конструктор чека для тестов.
Receipt makeReceipt(String id, {String? storeName = 'Магазин', double? total = 100}) =>
    Receipt(
      id: id,
      storeName: storeName,
      total: total,
      currency: 'RUB',
      status: ReceiptStatus.done,
      createdAt: DateTime.utc(2026, 6, 14, 10),
      photoPath: null,
    );

/// Фейк datasource: страницы из [all], опционально кидает [error].
class FakeReceiptsRemoteDataSource implements ReceiptsRemoteDataSource {
  FakeReceiptsRemoteDataSource(this.all);
  List<Receipt> all;
  Object? error;
  final List<String> deleted = [];

  @override
  Future<List<Receipt>> fetchPage({required int limit, required int offset}) async {
    if (error != null) throw error!;
    if (offset >= all.length) return [];
    return all.sublist(offset, math.min(offset + limit, all.length));
  }

  @override
  Future<ReceiptDetails> fetchById(String id) async {
    if (error != null) throw error!;
    return ReceiptDetails(
      receipt: all.firstWhere((r) => r.id == id),
      items: const [ReceiptItem(id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80)],
    );
  }

  @override
  Future<void> deleteById(String id) async {
    if (error != null) throw error!;
    deleted.add(id);
    all = all.where((r) => r.id != id).toList();
  }

  @override
  Future<String?> createPhotoUrl(String path) async => 'https://signed/$path';
}

/// Фейк репозитория для тестов контроллеров.
class FakeReceiptsRepository implements ReceiptsRepository {
  FakeReceiptsRepository(this.all);
  List<Receipt> all;
  Object? error;
  final List<String> deleted = [];

  @override
  Future<List<Receipt>> list({required int limit, required int offset}) async {
    if (error != null) throw error!;
    if (offset >= all.length) return [];
    return all.sublist(offset, math.min(offset + limit, all.length));
  }

  @override
  Future<ReceiptDetails> getById(String id) async {
    if (error != null) throw error!;
    return ReceiptDetails(
      receipt: all.firstWhere((r) => r.id == id),
      items: const [ReceiptItem(id: 'i1', rawName: 'Молоко', qty: 1, unitPrice: 80, sum: 80)],
    );
  }

  @override
  Future<void> delete(String id) async {
    if (error != null) throw error!;
    deleted.add(id);
    all = all.where((r) => r.id != id).toList();
  }

  @override
  Future<String?> photoUrl(String path) async => 'https://signed/$path';
}
```

- [ ] **Step 2: Написать падающий тест репозитория**

Создать `app/test/features/receipts/data/repositories/receipts_repository_impl_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';

import '../../receipts_test_fakes.dart';

void main() {
  test('list делегирует datasource и возвращает чеки', () async {
    final repo = ReceiptsRepositoryImpl(
        FakeReceiptsRemoteDataSource([makeReceipt('r1'), makeReceipt('r2')]));
    final page = await repo.list(limit: 25, offset: 0);
    expect(page.map((r) => r.id), ['r1', 'r2']);
  });

  test('delete делегирует datasource', () async {
    final ds = FakeReceiptsRemoteDataSource([makeReceipt('r1')]);
    await ReceiptsRepositoryImpl(ds).delete('r1');
    expect(ds.deleted, ['r1']);
  });

  test('исключение datasource → ReceiptsFailure', () async {
    final ds = FakeReceiptsRemoteDataSource([])..error = const SocketException('x');
    final repo = ReceiptsRepositoryImpl(ds);
    expect(() => repo.list(limit: 25, offset: 0), throwsA(isA<ReceiptsFailure>()));
  });
}
```

- [ ] **Step 3: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/data/repositories/receipts_repository_impl_test.dart`
Expected: FAIL (ReceiptsRepositoryImpl не определён).

- [ ] **Step 4: Реализовать репозиторий**

Создать `app/lib/features/receipts/data/repositories/receipts_repository_impl.dart`:

```dart
/// Назначение: реализация ReceiptsRepository поверх remote datasource.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: flutter_riverpod, datasources/receipts_remote_datasource.dart,
///   receipts_error_mapper.dart, domain/repositories/receipts_repository.dart.
/// Ключевые типы: ReceiptsRepositoryImpl, receiptsRepositoryProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../datasources/receipts_remote_datasource.dart';
import '../receipts_error_mapper.dart';

/// Делегирует datasource, оборачивает исключения в ReceiptsFailure.
class ReceiptsRepositoryImpl implements ReceiptsRepository {
  const ReceiptsRepositoryImpl(this._ds);

  final ReceiptsRemoteDataSource _ds;

  @override
  Future<List<Receipt>> list({required int limit, required int offset}) async {
    try {
      return await _ds.fetchPage(limit: limit, offset: offset);
    } catch (e) {
      throw mapReceiptsException(e);
    }
  }

  @override
  Future<ReceiptDetails> getById(String id) async {
    try {
      return await _ds.fetchById(id);
    } catch (e) {
      throw mapReceiptsException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _ds.deleteById(id);
    } catch (e) {
      throw const ReceiptsDeleteFailure();
    }
  }

  @override
  Future<String?> photoUrl(String path) async {
    try {
      return await _ds.createPhotoUrl(path);
    } catch (_) {
      return null; // отсутствие фото не должно ломать список
    }
  }
}

/// DI-провайдер репозитория чеков.
final receiptsRepositoryProvider = Provider<ReceiptsRepository>(
  (ref) => ReceiptsRepositoryImpl(ref.watch(receiptsRemoteDataSourceProvider)),
);
```

Примечание: импорт `ReceiptsDeleteFailure` приходит транзитивно через `receipts_error_mapper.dart`? Нет — добавить прямой импорт ошибок: убедиться, что `core/error/failure.dart` импортирован. Добавить в начало импорт:
`import '../../../../core/error/failure.dart';`

- [ ] **Step 5: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/data/repositories/receipts_repository_impl_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/receipts/data/repositories/ app/test/features/receipts/receipts_test_fakes.dart app/test/features/receipts/data/repositories/
git commit -m "feat(receipts): ReceiptsRepositoryImpl + DI + тест-фейки"
```

---

## Task 8: Контроллер списка с пагинацией (`ReceiptsListController`)

**Files:**
- Create: `app/lib/features/receipts/presentation/controllers/receipts_list_controller.dart`
- Test: `app/test/features/receipts/presentation/controllers/receipts_list_controller_test.dart`

- [ ] **Step 1: Реализовать состояние + контроллер**

Создать `app/lib/features/receipts/presentation/controllers/receipts_list_controller.dart`:

```dart
/// Назначение: контроллер списка чеков — пагинация (offset), удаление, refresh.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: riverpod_annotation, data/repositories/receipts_repository_impl.dart,
///   domain/entities/receipt.dart.
/// Ключевые типы: ReceiptsListState, ReceiptsListController,
///   receiptsListControllerProvider, kReceiptsPageSize.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/receipts_repository_impl.dart';
import '../../domain/entities/receipt.dart';

part 'receipts_list_controller.g.dart';

/// Размер страницы списка чеков.
const int kReceiptsPageSize = 25;

/// Снимок состояния списка: элементы, есть ли ещё, идёт ли догрузка.
class ReceiptsListState {
  const ReceiptsListState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Receipt> items;
  final bool hasMore;
  final bool isLoadingMore;

  ReceiptsListState copyWith({
    List<Receipt>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      ReceiptsListState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Грузит первую страницу; умеет догружать и удалять с перезапросом.
@riverpod
class ReceiptsListController extends _$ReceiptsListController {
  @override
  Future<ReceiptsListState> build() async {
    final page = await ref
        .watch(receiptsRepositoryProvider)
        .list(limit: kReceiptsPageSize, offset: 0);
    return ReceiptsListState(
      items: page,
      hasMore: page.length == kReceiptsPageSize,
    );
  }

  /// Догружает следующую страницу (idempotent при отсутствии данных/догрузке).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref.read(receiptsRepositoryProvider).list(
            limit: kReceiptsPageSize,
            offset: current.items.length,
          );
      state = AsyncData(ReceiptsListState(
        items: [...current.items, ...next],
        hasMore: next.length == kReceiptsPageSize,
      ));
    } catch (_) {
      // Догрузка не критична: снимаем флаг, страница останется как была.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Pull-to-refresh: перезагрузка с начала.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Удаляет чек и перезапрашивает список с начала.
  Future<void> deleteReceipt(String id) async {
    await ref.read(receiptsRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}
```

- [ ] **Step 2: Запустить кодоген**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: BUILD генерирует `receipts_list_controller.g.dart`, ошибок нет.

- [ ] **Step 3: Написать тест контроллера**

Создать `app/test/features/receipts/presentation/controllers/receipts_list_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipts_list_controller.dart';

import '../../receipts_test_fakes.dart';

ProviderContainer _container(FakeReceiptsRepository repo) {
  final c = ProviderContainer(overrides: [
    receiptsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

List _receipts(int n) =>
    List.generate(n, (i) => makeReceipt('r$i'));

void main() {
  test('первая загрузка отдаёт 25 и hasMore=true при 30 чеках', () async {
    final c = _container(FakeReceiptsRepository(_receipts(30).cast()));
    final state = await c.read(receiptsListControllerProvider.future);
    expect(state.items.length, 25);
    expect(state.hasMore, isTrue);
  });

  test('loadMore догружает остаток и ставит hasMore=false', () async {
    final c = _container(FakeReceiptsRepository(_receipts(30).cast()));
    await c.read(receiptsListControllerProvider.future);
    await c.read(receiptsListControllerProvider.notifier).loadMore();
    final state = c.read(receiptsListControllerProvider).requireValue;
    expect(state.items.length, 30);
    expect(state.hasMore, isFalse);
  });

  test('ровно 25 чеков → hasMore=false уже после первой страницы', () async {
    final c = _container(FakeReceiptsRepository(_receipts(25).cast()));
    final state = await c.read(receiptsListControllerProvider.future);
    expect(state.items.length, 25);
    expect(state.hasMore, isFalse);
  });

  test('deleteReceipt удаляет и перезапрашивает список', () async {
    final repo = FakeReceiptsRepository(_receipts(3).cast());
    final c = _container(repo);
    await c.read(receiptsListControllerProvider.future);
    await c.read(receiptsListControllerProvider.notifier).deleteReceipt('r0');
    final state = c.read(receiptsListControllerProvider).requireValue;
    expect(repo.deleted, ['r0']);
    expect(state.items.map((r) => r.id), ['r1', 'r2']);
  });

  test('ошибка загрузки → AsyncError(ReceiptsFailure)', () async {
    final repo = FakeReceiptsRepository([])..error = const ReceiptsLoadFailure();
    final c = _container(repo);
    await expectLater(
      c.read(receiptsListControllerProvider.future),
      throwsA(isA<ReceiptsFailure>()),
    );
  });
}
```

Примечание для исполнителя: `_receipts(n).cast()` приводит `List<dynamic>` к `List<Receipt>` — при желании заменить на типизированный генератор `List<Receipt>.generate(...)`.

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/controllers/receipts_list_controller_test.dart`
Expected: PASS (5 тестов).

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/presentation/controllers/receipts_list_controller.dart app/lib/features/receipts/presentation/controllers/receipts_list_controller.g.dart app/test/features/receipts/presentation/controllers/receipts_list_controller_test.dart
git commit -m "feat(receipts): контроллер списка с offset-пагинацией и удалением"
```

---

## Task 9: Провайдер деталей чека + провайдер signed URL фото

**Files:**
- Create: `app/lib/features/receipts/presentation/controllers/receipt_details_controller.dart`
- Test: `app/test/features/receipts/presentation/controllers/receipt_details_controller_test.dart`

- [ ] **Step 1: Реализовать провайдеры**

Создать `app/lib/features/receipts/presentation/controllers/receipt_details_controller.dart`:

```dart
/// Назначение: провайдеры деталей чека и signed URL фото чека.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: riverpod_annotation, data/repositories/receipts_repository_impl.dart,
///   domain/entities/receipt_details.dart.
/// Ключевые типы: receiptDetailsProvider, receiptPhotoUrlProvider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/receipts_repository_impl.dart';
import '../../domain/entities/receipt_details.dart';

part 'receipt_details_controller.g.dart';

/// Детали чека по id.
@riverpod
Future<ReceiptDetails> receiptDetails(ReceiptDetailsRef ref, String id) {
  return ref.watch(receiptsRepositoryProvider).getById(id);
}

/// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
@riverpod
Future<String?> receiptPhotoUrl(ReceiptPhotoUrlRef ref, String path) {
  return ref.watch(receiptsRepositoryProvider).photoUrl(path);
}
```

- [ ] **Step 2: Запустить кодоген**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: генерируется `receipt_details_controller.g.dart`.

- [ ] **Step 3: Написать тест**

Создать `app/test/features/receipts/presentation/controllers/receipt_details_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipt_details_controller.dart';

import '../../receipts_test_fakes.dart';

void main() {
  test('receiptDetailsProvider отдаёт чек с позициями', () async {
    final c = ProviderContainer(overrides: [
      receiptsRepositoryProvider
          .overrideWithValue(FakeReceiptsRepository([makeReceipt('r1')])),
    ]);
    addTearDown(c.dispose);
    final details = await c.read(receiptDetailsProvider('r1').future);
    expect(details.receipt.id, 'r1');
    expect(details.items, isNotEmpty);
  });

  test('receiptPhotoUrlProvider отдаёт signed URL', () async {
    final c = ProviderContainer(overrides: [
      receiptsRepositoryProvider
          .overrideWithValue(FakeReceiptsRepository([])),
    ]);
    addTearDown(c.dispose);
    final url = await c.read(receiptPhotoUrlProvider('uid/x.jpg').future);
    expect(url, 'https://signed/uid/x.jpg');
  });
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/controllers/receipt_details_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/presentation/controllers/receipt_details_controller.dart app/lib/features/receipts/presentation/controllers/receipt_details_controller.g.dart app/test/features/receipts/presentation/controllers/receipt_details_controller_test.dart
git commit -m "feat(receipts): провайдеры деталей чека и signed URL фото"
```

---

## Task 10: Виджет миниатюры фото `ReceiptPhotoThumbnail`

**Files:**
- Create: `app/lib/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart`
- Test: `app/test/features/receipts/presentation/widgets/receipt_photo_thumbnail_test.dart`

- [ ] **Step 1: Написать падающий widget-тест (плейсхолдер при отсутствии фото)**

Создать `app/test/features/receipts/presentation/widgets/receipt_photo_thumbnail_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('без photoPath показывает иконку-плейсхолдер', (tester) async {
    await pumpApp(tester, const ReceiptPhotoThumbnail(photoPath: null));
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/presentation/widgets/receipt_photo_thumbnail_test.dart`
Expected: FAIL (виджет не определён).

- [ ] **Step 3: Реализовать виджет**

Создать `app/lib/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart`:

```dart
/// Назначение: квадратная миниатюра фото чека (signed URL) или плейсхолдер.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, core/theme/app_tokens.dart,
///   controllers/receipt_details_controller.dart.
/// Ключевые типы: ReceiptPhotoThumbnail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../controllers/receipt_details_controller.dart';

/// Миниатюра фото чека размером [size]; при отсутствии фото — иконка.
class ReceiptPhotoThumbnail extends ConsumerWidget {
  const ReceiptPhotoThumbnail({required this.photoPath, this.size = 56, super.key});

  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusSm);

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: radius,
          ),
          child: Icon(Icons.receipt_long_outlined, color: scheme.onSurfaceVariant),
        );

    final path = photoPath;
    if (path == null) return placeholder();

    final urlAsync = ref.watch(receiptPhotoUrlProvider(path));
    return ClipRRect(
      borderRadius: radius,
      child: urlAsync.maybeWhen(
        data: (url) => url == null
            ? placeholder()
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              ),
        orElse: placeholder,
      ),
    );
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/widgets/receipt_photo_thumbnail_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart app/test/features/receipts/presentation/widgets/receipt_photo_thumbnail_test.dart
git commit -m "feat(receipts): миниатюра фото чека с плейсхолдером"
```

---

## Task 11: Бейдж статуса + строка списка `ReceiptListItem` (slidable)

**Files:**
- Create: `app/lib/features/receipts/presentation/widgets/receipt_status_badge.dart`
- Create: `app/lib/features/receipts/presentation/widgets/receipt_list_item.dart`
- Test: `app/test/features/receipts/presentation/widgets/receipt_list_item_test.dart`

- [ ] **Step 1: Реализовать бейдж статуса**

Создать `app/lib/features/receipts/presentation/widgets/receipt_status_badge.dart`:

```dart
/// Назначение: бейдж статуса чека (маппинг ReceiptStatus → AppBadge).
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, shared/components (AppBadge),
///   domain/entities/receipt_status.dart.
/// Ключевые типы: ReceiptStatusBadge.
library;

import 'package:flutter/material.dart';

import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt_status.dart';

/// Бейдж со статусом чека и соответствующей тональностью.
class ReceiptStatusBadge extends StatelessWidget {
  const ReceiptStatusBadge({required this.status, super.key});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      ReceiptStatus.pending => AppBadgeTone.neutral,
      ReceiptStatus.processing => AppBadgeTone.warning,
      ReceiptStatus.done => AppBadgeTone.success,
      ReceiptStatus.failed => AppBadgeTone.error,
    };
    return AppBadge(label: status.label, tone: tone);
  }
}
```

- [ ] **Step 2: Написать падающий widget-тест строки**

Создать `app/test/features/receipts/presentation/widgets/receipt_list_item_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_list_item.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_status_badge.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('показывает название магазина, сумму и бейдж статуса', (tester) async {
    await pumpApp(
      tester,
      ReceiptListItem(
        receipt: makeReceipt('r1', storeName: 'Пятёрочка', total: 250),
        onTap: () {},
        onDelete: () async {},
      ),
    );
    expect(find.text('Пятёрочка'), findsOneWidget);
    expect(find.textContaining('250'), findsWidgets);
    expect(find.byType(ReceiptStatusBadge), findsOneWidget);
  });

  testWidgets('без названия магазина показывает фолбэк', (tester) async {
    await pumpApp(
      tester,
      ReceiptListItem(
        receipt: makeReceipt('r2', storeName: null),
        onTap: () {},
        onDelete: () async {},
      ),
    );
    expect(find.text('Магазин не определён'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/presentation/widgets/receipt_list_item_test.dart`
Expected: FAIL (ReceiptListItem не определён).

- [ ] **Step 4: Реализовать строку списка**

Создать `app/lib/features/receipts/presentation/widgets/receipt_list_item.dart`:

```dart
/// Назначение: строка списка чеков со свайп-удалением (slidable) и тапом.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_slidable, intl, core/theme/app_tokens.dart,
///   shared/components, domain/entities/receipt.dart, widgets (thumbnail/status badge).
/// Ключевые типы: ReceiptListItem.
library;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt.dart';
import 'receipt_photo_thumbnail.dart';
import 'receipt_status_badge.dart';

/// Фолбэк-название, когда магазин ещё не распознан воркером.
const String _storeFallback = 'Магазин не определён';

/// Строка чека: фото, магазин, сумма, дата, статус; свайп → удаление.
class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({
    required this.receipt,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Receipt receipt;
  final VoidCallback onTap;

  /// Подтверждённое удаление (диалог уже пройден).
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(receipt.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (ctx) => _confirmAndDelete(ctx),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            icon: Icons.delete_outline,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
        ],
      ),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            ReceiptPhotoThumbnail(photoPath: receipt.photoPath),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.storeName ?? _storeFallback,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  if (receipt.total != null && receipt.currency != null)
                    MoneyText(
                      receipt.total!,
                      currencyCode: receipt.currency!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toString(),
                    ).add_Hm().format(receipt.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            ReceiptStatusBadge(status: receipt.status),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чек?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete();
  }
}
```

Примечание для исполнителя: проверить точную сигнатуру `AppButton` (`label`/`onPressed`/`variant`) в `app/lib/shared/components/app_button.dart` и при расхождении привести вызовы в соответствие.

- [ ] **Step 5: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/widgets/receipt_list_item_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/lib/features/receipts/presentation/widgets/receipt_status_badge.dart app/lib/features/receipts/presentation/widgets/receipt_list_item.dart app/test/features/receipts/presentation/widgets/receipt_list_item_test.dart
git commit -m "feat(receipts): строка списка со свайп-удалением и бейджем статуса"
```

---

## Task 12: Экран списка `ReceiptsScreen` (состояния + пагинация по скроллу)

**Files:**
- Modify: `app/lib/features/receipts/presentation/screens/receipts_screen.dart`
- Modify (переписать): `app/test/features/receipts/presentation/screens/receipts_screen_test.dart`

- [ ] **Step 1: Переписать тест экрана**

Заменить содержимое `app/test/features/receipts/presentation/screens/receipts_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_list_item.dart';
import 'package:ticket_app/shared/components/components.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('пустой список → AppEmptyState', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider
            .overrideWithValue(FakeReceiptsRepository([])),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('есть чеки → рендерятся строки списка', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider.overrideWithValue(
          FakeReceiptsRepository(
              [makeReceipt('r1'), makeReceipt('r2'), makeReceipt('r3')]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptListItem), findsNWidgets(3));
  });

  testWidgets('ошибка загрузки → AppErrorView', (tester) async {
    final repo = FakeReceiptsRepository([])
      ..error = Exception('boom'); // станет AsyncError
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [receiptsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);
  });
}
```

Примечание: `makeReceipt` создаёт чеки с `photoPath: null` — поэтому `Image.network` в тесте не вызывается.

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/presentation/screens/receipts_screen_test.dart`
Expected: FAIL (старый экран показывает только AppEmptyState; строки/ошибка не находятся).

- [ ] **Step 3: Реализовать экран**

Заменить содержимое `app/lib/features/receipts/presentation/screens/receipts_screen.dart`:

```dart
/// Назначение: экран списка чеков — пагинация по скроллу, pull-to-refresh, удаление.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, go_router, core/theme/app_tokens.dart,
///   core/router/app_routes.dart, shared/components, controllers/receipts_list_controller.dart,
///   widgets/receipt_list_item.dart.
/// Ключевые типы: ReceiptsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/receipts_list_controller.dart';
import '../widgets/receipt_list_item.dart';

/// Список чеков пользователя.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(receiptsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(receiptsListControllerProvider.notifier).deleteReceipt(id);
    } catch (e) {
      if (!mounted) return;
      final message =
          e is Failure ? e.message : 'Не удалось удалить чек';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(receiptsListControllerProvider);

    final body = state.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(
        message: e is Failure ? e.message : 'Не удалось загрузить чеки',
        onRetry: () =>
            ref.read(receiptsListControllerProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const AppEmptyState(message: 'Здесь появятся ваши чеки');
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(receiptsListControllerProvider.notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.all(tokens.spaceMd),
            itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: tokens.spaceSm),
            itemBuilder: (context, index) {
              if (index >= data.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppLoader(),
                );
              }
              final receipt = data.items[index];
              return ReceiptListItem(
                receipt: receipt,
                onTap: () => context.push(AppRoutes.receiptDetailPath(receipt.id)),
                onDelete: () => _delete(receipt.id),
              );
            },
          ),
        );
      },
    );

    return AppScaffold(title: 'Чеки', body: body);
  }
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/screens/receipts_screen_test.dart`
Expected: PASS (3 теста). Примечание: метод `AppRoutes.receiptDetailPath` добавляется в Task 14 — до этого экран не скомпилируется. Поэтому выполнять Task 14 перед прогоном этого шага, либо временно заменить на `'/receipts/${receipt.id}'` и поправить в Task 14.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/presentation/screens/receipts_screen.dart app/test/features/receipts/presentation/screens/receipts_screen_test.dart
git commit -m "feat(receipts): экран списка чеков (состояния, пагинация по скроллу, удаление)"
```

---

## Task 13: Экран деталей `ReceiptDetailsScreen`

**Files:**
- Create: `app/lib/features/receipts/presentation/screens/receipt_details_screen.dart`
- Test: `app/test/features/receipts/presentation/screens/receipt_details_screen_test.dart`

- [ ] **Step 1: Написать падающий widget-тест**

Создать `app/test/features/receipts/presentation/screens/receipt_details_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipt_details_screen.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_status_badge.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('рендерит магазин, статус и позиции чека', (tester) async {
    await pumpApp(
      tester,
      const ReceiptDetailsScreen(id: 'r1'),
      overrides: [
        receiptsRepositoryProvider.overrideWithValue(
          FakeReceiptsRepository([makeReceipt('r1', storeName: 'Лента')]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('Лента'), findsOneWidget);
    expect(find.byType(ReceiptStatusBadge), findsOneWidget);
    expect(find.text('Молоко'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd app && flutter test test/features/receipts/presentation/screens/receipt_details_screen_test.dart`
Expected: FAIL (экран не определён).

- [ ] **Step 3: Реализовать экран**

Создать `app/lib/features/receipts/presentation/screens/receipt_details_screen.dart`:

```dart
/// Назначение: экран деталей чека — шапка (магазин/сумма/дата/статус), фото, позиции.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, intl, core/error/failure.dart,
///   core/theme/app_tokens.dart, shared/components, controllers/receipt_details_controller.dart,
///   widgets (thumbnail/status badge), domain/entities.
/// Ключевые типы: ReceiptDetailsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt_details.dart';
import '../controllers/receipt_details_controller.dart';
import '../widgets/receipt_photo_thumbnail.dart';
import '../widgets/receipt_status_badge.dart';

/// Детальный просмотр чека по [id].
class ReceiptDetailsScreen extends ConsumerWidget {
  const ReceiptDetailsScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptDetailsProvider(id));
    final body = async.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(
        message: e is Failure ? e.message : 'Не удалось загрузить чек',
        onRetry: () => ref.invalidate(receiptDetailsProvider(id)),
      ),
      data: (details) => _DetailsBody(details: details),
    );
    return AppScaffold(title: 'Чек', body: body);
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.details});

  final ReceiptDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final r = details.receipt;
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: EdgeInsets.all(tokens.spaceMd),
      children: [
        Row(
          children: [
            ReceiptPhotoThumbnail(photoPath: r.photoPath, size: 72),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.storeName ?? 'Магазин не определён',
                      style: theme.textTheme.titleLarge),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    DateFormat.yMMMMd(locale).add_Hm().format(r.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ReceiptStatusBadge(status: r.status),
          ],
        ),
        SizedBox(height: tokens.spaceLg),
        if (r.total != null && r.currency != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого', style: theme.textTheme.titleMedium),
              MoneyText(r.total!,
                  currencyCode: r.currency!, style: theme.textTheme.titleMedium),
            ],
          ),
        const Divider(height: 32),
        Text('Позиции', style: theme.textTheme.titleMedium),
        SizedBox(height: tokens.spaceSm),
        if (details.items.isEmpty)
          Text('Позиции ещё не распознаны',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          ...details.items.map(
            (it) => Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
              child: Row(
                children: [
                  Expanded(child: Text(it.rawName, style: theme.textTheme.bodyMedium)),
                  SizedBox(width: tokens.spaceSm),
                  Text('${_qty(it.qty)} × ',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  if (r.currency != null)
                    MoneyText(it.sum,
                        currencyCode: r.currency!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _qty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd app && flutter test test/features/receipts/presentation/screens/receipt_details_screen_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/receipts/presentation/screens/receipt_details_screen.dart app/test/features/receipts/presentation/screens/receipt_details_screen_test.dart
git commit -m "feat(receipts): экран деталей чека (шапка, фото, позиции)"
```

---

## Task 14: Маршрут деталей чека

**Files:**
- Modify: `app/lib/core/router/app_routes.dart`
- Modify: `app/lib/core/router/app_router.dart`

- [ ] **Step 1: Добавить путь в `app_routes.dart`**

В классе `AppRoutes` добавить после `static const String profile = '/profile';`:

```dart
  /// Шаблон маршрута деталей чека (вложен в ветку receipts).
  static const String receiptDetail = '/receipts/:id';

  /// Путь к деталям конкретного чека.
  static String receiptDetailPath(String id) => '/receipts/$id';
```

- [ ] **Step 2: Добавить вложенный маршрут в `app_router.dart`**

В ветке receipts заменить блок `GoRoute(path: AppRoutes.receipts, builder: ...)` на вариант с дочерним маршрутом и добавить импорт экрана деталей вверху файла
(`import '../../features/receipts/presentation/screens/receipt_details_screen.dart';`):

```dart
              GoRoute(
                path: AppRoutes.receipts,
                builder: (context, state) => const ReceiptsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => ReceiptDetailsScreen(
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
```

- [ ] **Step 3: Проверить анализатором + весь пакет тестов**

Run: `cd app && dart analyze && flutter test`
Expected: анализ без ошибок; все тесты PASS (включая `receipts_screen_test.dart`, который использует `AppRoutes.receiptDetailPath`).

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/router/app_routes.dart app/lib/core/router/app_router.dart
git commit -m "feat(receipts): маршрут деталей чека /receipts/:id"
```

---

## Task 15: Живая документация + ADR

**Files:**
- Modify: `docs/features/receipts.md`
- Modify: `docs/architecture/data-model.md`
- Create: `docs/adr/0002-receipts-pagination.md`

- [ ] **Step 1: Обновить `docs/features/receipts.md`**

В разделе «Экраны / UI» отметить, что реализованы: список с пагинацией (25/страница, `created_at desc`), свайп-удаление (slidable + диалог, refetch после удаления), экран деталей (шапка + позиции + фото). Добавить пометки:
- название магазина — join `stores(name)`, фолбэк «Магазин не определён» при `null`;
- Realtime-статус (`receiptStatusProvider`) и семейные чеки — НЕ реализованы (отдельные циклы).
В «Открытые вопросы» оставить поведение при `failed`.

- [ ] **Step 2: Обновить `docs/architecture/data-model.md`**

В блоке-цитате про `receipts` убрать формулировку «без FK на stores»; зафиксировать: миграцией `0004_stores_chains.sql` созданы `stores`/`chains` (зона B), добавлен FK `receipts.store_id → stores.id` (`on delete set null`). В таблице зоны B пометить `stores`/`chains` как созданные.

- [ ] **Step 3: Создать ADR `docs/adr/0002-receipts-pagination.md`**

```markdown
# 0002. Пагинация списков: range/offset

Дата: 2026-06-14
Статус: принято

## Контекст
Списку чеков нужна подгрузка по скроллу. В проекте не было паттерна пагинации.

## Решение
Используем offset-пагинацию через PostgREST `.range(from, to)` с сортировкой
по `created_at desc`, размер страницы 25 (`kReceiptsPageSize`). Состояние держит
рукописный Riverpod `AsyncNotifier` (`items + hasMore + isLoadingMore`). После
мутаций (удаление) — полный refetch с начала через `ref.invalidateSelf()`.

## Последствия
- Просто, без внешних пакетов; единый паттерн для будущих списков.
- При активных вставках возможны сдвиги окна; приемлемо (refetch после мутаций).
- Если понадобится строгая стабильность — мигрируем на keyset/cursor отдельным ADR.
```

- [ ] **Step 4: Commit**

```bash
git add docs/features/receipts.md docs/architecture/data-model.md docs/adr/0002-receipts-pagination.md
git commit -m "docs(receipts): обновить фичу/модель данных + ADR про пагинацию"
```

---

## Финальная верификация

- [ ] **Полный прогон тестов и анализатора**

Run: `cd app && dart analyze && flutter test`
Expected: No issues found; все тесты PASS.

- [ ] **Ручная проверка на симуляторе (по памяти проекта: boot + bootstatus, затем run-dev.sh)**

Запустить приложение (`app/run-dev.sh` к dev-проекту CheckPrices), на вкладке «Чеки»:
проверить загрузку списка, подгрузку по скроллу, свайп-удаление с диалогом и обновление
списка, переход в детали по тапу. Если чеков нет — создать через экран скана.
(Опционально: вставить тестовые строки в `stores` и проставить `receipts.store_id`,
чтобы увидеть название магазина.)

---

## Self-Review (выполнено автором плана)

- **Покрытие спека:** список+сортировка (Task 8/12), строка с фото/магазином/суммой/датой
  (Task 10/11), свайп-удаление + диалог + refetch (Task 8/11/12), пагинация 25 + скролл
  (Task 8/12), переход в детали (Task 12/13/14), полный экран деталей (Task 13), таблица
  stores + FK + join (Task 1/5/6), фолбэк имени (Task 11), документация/ADR (Task 15). Realtime
  и семья — явно вне скоупа. Пробелов нет.
- **Плейсхолдеры:** не обнаружено; весь код приведён.
- **Согласованность типов:** `receiptsRepositoryProvider`, `receiptsListControllerProvider`,
  `receiptDetailsProvider`, `receiptPhotoUrlProvider`, `ReceiptsListState`, `kReceiptsPageSize`,
  `AppRoutes.receiptDetailPath`, `kReceiptColumns/kReceiptItemColumns`, `receiptFromRow/
  receiptItemFromRow`, фейки — имена консистентны между задачами. Учтены зависимости задач
  (Task 12 ссылается на `AppRoutes.receiptDetailPath` из Task 14 — отмечено в шаге).
```
