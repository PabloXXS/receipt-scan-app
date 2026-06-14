# Дизайн: живой скан QR + OCR позиций (iOS-first) — первый срез

- **Дата:** 2026-06-14
- **Фича:** `scan` (расширение)
- **Статус:** утверждён (brainstorming)
- **Связанные доки:** [features/scan.md](../../features/scan.md),
  [features/receipts.md](../../features/receipts.md),
  [architecture/data-model.md](../../architecture/data-model.md),
  [architecture/data-flow.md](../../architecture/data-flow.md),
  предыдущий цикл — [specs/2026-06-09-scan-design.md](2026-06-09-scan-design.md)

## 1. Контекст и вердикт разведки (почему так)

Цель продукта: бесплатно — скан чека и получение позиций; платно (позже) — «анализ»
позиций. Первая попытка — «позиции по QR».

**Разведка показала (зафиксировано как обоснование решений):**
- QR белорусского чека несёт только **УИ** (учётный идентификатор, 24 символа;
  пример `2B08EC6FC311084007193733`), не ссылку и не позиции.
- Единственный авторитетный источник состава чека по УИ — официальный сервис СККО
  `ch.info-center.by` (МНС РБ). Он показывает полный состав, **но только веб-форма
  за Google reCAPTCHA, без публичного API**. Официальное приложение «Проверка чека
  покупателем» использует **закрытый** API info-center.
- Публичного/документированного API нет; готовых проектов под СККО РБ нет.

**Вывод:** чистого, легального, real-time способа получить позиции **по QR** из
стороннего приложения нет. Поэтому источник позиций — **OCR по фото**, а QR
используется только для извлечения/сохранения УИ.

## 2. Объём первого среза

Экран «Скан» → живая камера: real-time детект QR (→ УИ) + захват снимка → **Apple
Vision OCR** (рус.) → **парсер** → `ReceiptDraft` → экран-ревью (список позиций,
итог, УИ) → «Сохранить»/«Отмена». «Сохранить» пишет чек + позиции в БД. **iOS-only.**

### Не входит (отдельные циклы)
- Android-движок OCR (Apple Vision — только iOS).
- **LLM-парсинг** (будущая платная фича) — закладываем абстракцию движка, не реализуем.
- Фискальный API/PHP-воркер, Storage-загрузка фото, pgmq.
- Мультикадр-стичинг длинного чека (вариант C) — добавим, если одного кадра не хватит.
- Тиры/пейволл, нормализация товаров (`products`/`product_aliases`), карта цен.
- Полноценное редактирование позиций (см. §3).

## 3. Редактирование позиций — решение

Первый срез: **ревью только для чтения** + «Сохранить»/«Отмена» + удаление ошибочной
строки свайпом (дёшево, пересчёт итога). Полноценное редактирование полей
(название/кол-во/цена с пересчётом) — **следующий инкремент** (OCR неидеален, оно
нужно, но заметно раздувает UI; выносим из MVP по YAGNI).

## 4. Архитектура

### 4.1 Нативный iOS-модуль (Swift, в `app/ios/Runner`)
`ReceiptScanner` — единый Vision-конвейер:
- **AVFoundation**: сессия захвата, live-превью, снятие высокого кадра.
- **Vision**: `VNDetectBarcodesRequest` (QR → УИ, в реальном времени по кадрам
  превью) + `VNRecognizeTextRequest` (`recognitionLanguages = ["ru-RU"]`,
  `recognitionLevel = .accurate`) по захваченному снимку.
- Наружу:
  - **PlatformView** (`UiKitView`) — live-превью камеры.
  - **EventChannel** `scan/qr` — поток обнаруженных УИ.
  - **MethodChannel** `scan/ocr` — `recognizeText() → { lines: [{text, y, x, h}] }`
    по текущему снимку (строки с координатами для парсера).

### 4.2 Flutter — фича `scan` (расширяем существующую)
**domain/**
- `entities/receipt_draft.dart` — `ReceiptDraft(items, total, purchasedAt, qrRaw, currency)`,
  `ReceiptItemDraft(rawName, qty, unitPrice, sum)`.
- `entities/ocr_result.dart` — `OcrResult(lines)`, `OcrLine(text, top, left, height)`.
- `ocr/receipt_ocr_engine.dart` — контракт `ReceiptOcrEngine { Future<OcrResult> recognize(); }`
  (Vision-реализация сейчас, LLM-реализация — позже; абстракция намеренно тонкая).
- `ocr/receipt_parser.dart` — контракт `ReceiptParser { ReceiptDraft parse(OcrResult); }`.
- `repositories/scan_repository.dart` — добавить `Future<String> saveScannedReceipt(ReceiptDraft)`.
- `usecases/save_scanned_receipt.dart`.

**data/**
- `vision_ocr_engine.dart` — `ReceiptOcrEngine` поверх MethodChannel `scan/ocr`.
- `qr_scanner.dart` — обёртка над EventChannel `scan/qr` (поток УИ).
- `receipt_parser_impl.dart` — эвристический парсер строк → `ReceiptDraft`
  (см. §5). Отдельный файл, покрыт юнит-тестами.
- `datasources/scan_remote_datasource.dart` — добавить `insertReceiptWithItems(...)`
  (insert `receipts` + bulk insert `receipt_items`).
- `repositories/scan_repository_impl.dart` — реализовать `saveScannedReceipt`.

**presentation/**
- `screens/live_scan_screen.dart` — PlatformView-превью + QR-оверлей + кнопка «Снять».
- `screens/receipt_review_screen.dart` — список позиций, итог, УИ, «Сохранить»/«Отмена»,
  свайп-удаление строки.
- `controllers/scan_controller.dart` — расширить машину состояний:
  `live → captured(draft) → saving → saved(receiptId) / error`.

## 5. Парсер (`ReceiptParserImpl`)
Вход — строки OCR с координатами (сортировка по `top`). Эвристики под формат ProStore/РБ:
- Позиция = строка с кодом+названием (`^\d{6,}\s+.+` или `[M] \d+ ...`), за которой
  следует строка цены вида `<цена> *<кол-во> <сумма>` (десятичные через `.`).
- Многострочные названия склеиваются до строки цены.
- `total` — из строки `ИТОГО К ОПЛАТЕ <сумма>`; `purchasedAt` — из `дд.мм.гггг чч:мм:сс`;
  `currency` — из профиля (BY → BYN).
- Контрольная сверка: сумма позиций ≈ `total` (флаг несоответствия в draft).

Парсер — чистая функция от `OcrResult`, без платформы → полностью юнит-тестируемая.

## 6. Данные / БД — миграция `0003_receipt_items`
Таблица **`receipt_items`** (зона A), по data-model:
`id uuid pk, receipt_id uuid not null → receipts(id) on delete cascade,
user_id uuid not null, family_id uuid, raw_name text not null,
product_id uuid (null, без FK — products зоны B ещё нет), qty numeric(12,3),
unit_price numeric(12,2), sum numeric(12,2), created_at timestamptz`.

RLS (зона A): `select/insert/delete` по `user_id = auth.uid()` (семейное правило —
позже). BEFORE INSERT триггер заполняет `user_id := auth.uid()` и `family_id` из
профиля (как в `receipts`). Прогон через субагент **`privacy-rls-reviewer`**.

**Сохранение чека (клиентский OCR-путь):** insert `receipts`
(`source = ScanSource.ocr.dbValue`, `qr_raw = УИ`, `status = 'done'`, `total`,
`purchased_at`, `currency`) → получить id → bulk insert `receipt_items`.
**Без Storage-загрузки и без pgmq** (воркера нет; позиции уже разобраны на клиенте).
Существующие триггеры `receipts`: `receipts_fill_owner` отработает; `receipts_enqueue`
поставит сообщение в pgmq — **это допустимо** (воркер его не читает; чек уже `done`).
> Решение: оставляем `receipts_enqueue` как есть; лишнее сообщение в очереди
> безвредно. Отключение enqueue для done-вставок — вне объёма.

## 7. Поток данных
Камера → (QR live → УИ в стейт) → «Снять» → Vision OCR → `OcrResult` →
`ReceiptParserImpl` → `ReceiptDraft` → ReviewScreen → «Сохранить» →
`SaveScannedReceipt` → datasource → `receipts` + `receipt_items` → `saved`.

## 8. Обработка ошибок
- Нет доступа к камере → экран с подсказкой открыть настройки (`CameraPermissionDeniedFailure`).
- QR не обнаружен → разрешаем сохранять без УИ (`qr_raw = null`).
- OCR пусто/не распарсилось в позиции → состояние «не удалось распознать, переснять».
- Сбой сохранения → `UploadFailure`-аналог из семейства `ScanFailure`; `ReceiptDraft`
  не теряется (возврат на ReviewScreen).

## 9. Тестирование
- **Парсер** — юнит-тесты на реальных строках OCR чека ProStore (14 позиций, итог
  **65.89**): извлечение позиций, склейка многострочных названий, итог/дата, контрольная
  сверка суммы. Это главный тест точности.
- usecase / контроллер / datasource — фейки на границах.
- Виджет-тесты `ReceiptReviewScreen` (рендер списка, Сохранить/Отмена, свайп-удаление).
- Нативный Vision-модуль и `LiveScanScreen` (PlatformView) — **ручная проверка на
  реальном iPhone** (камера/Vision не работают на симуляторе; юнит-тестами не покрыть).

## 10. Риски (честно)
- **Точность парсера на кириллице с фото** — главный риск; мятые/длинные чеки дают
  ошибки → отсюда важность будущего редактирования (§3) и LLM-движка.
- **Длинный чек в один кадр** может не поместиться читаемо (тестовый чек не влез —
  снят в два фото) → при плохих результатах добавляем мультикадр (вариант C) отдельным циклом.
- Значительный объём (нативный Swift-модуль + парсер + 2 экрана + миграция), но цельный
  и демонстрируемый на устройстве.
- Нативный модуль и e2e не проверяются автоматически/на симуляторе — только живой iPhone.
