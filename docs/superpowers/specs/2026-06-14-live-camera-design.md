# Дизайн: живое превью камеры в приложении (Фаза 2, iOS)

- **Дата:** 2026-06-14
- **Фича:** `scan` (расширение)
- **Статус:** утверждён (brainstorming)
- **Связанные доки:** [features/scan.md](../../features/scan.md),
  предыдущая фаза — [specs/2026-06-14-qr-ocr-scan-design.md](2026-06-14-qr-ocr-scan-design.md)

## 1. Контекст и объём

Фаза 1 даёт OCR-конвейер «снимок → Apple Vision (текст+QR) → парсер → ревью →
сохранение», где снимок берётся через `image_picker` (камера-шторка ОС или галерея).
Пользователь хотел камеру **внутри приложения** (живое превью), а не системную шторку.

**Объём Фазы 2 (лёгкий вариант):** живое превью камеры в приложении + кнопка-затвор →
снимок передаётся в существующий OCR-конвейер. iOS-only.

### Сознательные решения
- **Real-time QR-оверлей НЕ делаем** (отклонён): QR даёт лишь УИ, позиции всё равно
  из снимка; нативный AVFoundation+Vision на потоке не оправдан для текущей ценности.
- **Галерея остаётся** (`image_picker`) — и как fallback, и как единственный путь,
  тестируемый на симуляторе (у симулятора нет камеры).
- Плагин **`camera`** (официальный, AVFoundation): собирается на симуляторе; реальный
  кадр/съёмка — только на устройстве.

### Не входит
- Android; real-time детекция/подсветка QR; LLM-парсер; редактирование полей позиций.

## 2. Архитектура

**Поток:** экран захвата → «Камера» → `LiveCameraScreen` (превью + затвор) → `takePicture()`
→ байты → `ScanController.recognizePhoto(bytes)` → `ScanRecognizing` → парсер → `ScanReview`
→ «Сохранить». «Из галереи» → `ScanController.pickFromGallery()` (без изменений).

Плагин камеры изолирован в `LiveCameraScreen`; контроллер от него не зависит — принимает
готовые байты, поэтому остаётся юнит-тестируемым.

### Файлы
- `app/pubspec.yaml` — добавить зависимость `camera`.
- Create `app/lib/features/scan/presentation/screens/live_camera_screen.dart` —
  `CameraController` (init/dispose по lifecycle), `CameraPreview`, кнопка-затвор; на снимке
  `takePicture()` → `readAsBytes()` → `ref.read(scanControllerProvider.notifier).recognizePhoto(bytes)` → `Navigator.pop`.
- Modify `app/lib/features/scan/presentation/controllers/scan_controller.dart` —
  выделить публичный `Future<void> recognizePhoto(Uint8List bytes)` из текущего `_capture`
  (OCR через `receiptOcrEngineProvider` → парсинг через `receiptParserProvider` → `ScanReview`;
  ошибки → `ScanError`). `pickFromGallery()` остаётся через `PhotoPicker`. Метод
  `pickFromCamera()` (image_picker-камера) удаляется — заменяется живой камерой.
- Modify `app/lib/features/scan/presentation/widgets/scan_capture_view.dart` — кнопка
  «Камера» открывает `LiveCameraScreen` (`Navigator.push`); «Из галереи» вызывает
  `pickFromGallery()` (без изменений).
- iOS: `NSCameraUsageDescription` уже есть (Фаза 1) — менять не нужно.

## 3. Состояния
Машина состояний `ScanController` не меняется (`ScanIdle/ScanRecognizing/ScanReview/
ScanSaving/ScanSaved/ScanError`). Камера лишь поставляет байты в `recognizePhoto`.

## 4. Обработка ошибок
- Нет доступа к камере (`CameraException` permission) → `LiveCameraScreen` показывает
  сообщение с предложением открыть настройки / вернуться и выбрать из галереи.
- Камера недоступна (нет устройств — симулятор) → сообщение «камера недоступна,
  используйте галерею», кнопка возврата.
- Ошибка инициализации/съёмки → сообщение + возврат; `ScanController` не трогается.
- Ошибки распознавания/сохранения — как в Фазе 1 (`ScanError`, `mapScanException`).

## 5. Тестирование
- **`recognizePhoto(bytes)`** — юнит-тест контроллера с `FakeOcrEngine` + реальным
  `ReceiptParserImpl` (на фикстуре `prostoreOcrLines`): байты → `ScanReview` с позициями;
  ошибка движка → `ScanError`. Тестируемо без устройства.
- Галерейный путь (`pickFromGallery` → review → save) — существующий widget-тест scan_screen
  адаптировать под кнопку «Из галереи» (если изменилось имя), остальное без изменений.
- `LiveCameraScreen` (плагин `camera`) — **ручная проверка на реальном iPhone**: превью,
  затвор, снимок → распознавание → ревью → сохранение. На симуляторе проверяется только
  сборка (превью пустое).

## 6. Риски
- Плагин `camera` тестируется вживую только на устройстве; на симуляторе превью пустое.
- Качество снимка с рук (фокус/смаз) влияет на OCR — то же ограничение, что в Фазе 1.
- `recognizePhoto` рефакторится из `_capture` — нужно сохранить существующее поведение
  галерейного пути (покрыто тестами контроллера).
