# Запуск приложения в эмуляторе (iOS-симулятор, macOS)

Шпаргалка по локальному запуску ChekiPrices на iOS-симуляторе Mac.

## Быстрый старт

```bash
cd app

# 1. Узнать id нужного симулятора
xcrun simctl list devices available | grep iPhone

# 2. Поднять симулятор и ДОЖДАТЬСЯ загрузки (важно!)
DEVICE=<device-id>                  # напр. B7B8D185-455F-42A7-8FEC-DA6B2F3F861D
xcrun simctl boot "$DEVICE"         # если уже booted — вернёт ошибку, игнорируем
open -a Simulator                   # показать окно симулятора
xcrun simctl bootstatus "$DEVICE"   # блокирует, пока устройство не догрузится

# 3. Запуск с dev-кредами Supabase на этом устройстве
./run-dev.sh "$DEVICE"
```

> ⚠️ **Flutter видит только загруженные (booted) симуляторы.** Выключенный
> симулятор не появится в `flutter run`/`flutter devices`, и запуск упадёт с
> `No supported devices found with name or id matching ...`. Поэтому сначала
> `boot` + `bootstatus`, и только потом `run` — связки `open -a Simulator && run`
> недостаточно (`open` не дожидается загрузки устройства).

> `run-dev.sh` лежит локально (в `.gitignore`) и содержит dev-URL и публичный
> anon-ключ Supabase. Если его нет — создайте по образцу из раздела «Без скрипта».

## Без скрипта (ручная команда)

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # если меняли codegen

# Симулятор должен быть уже booted (см. шаг 2 «Быстрого старта»)
flutter run -d <device-id> \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

`-d` matchит по **id или имени** устройства (не по платформе!). Поэтому `-d ios`
**не работает** — `ios` это target platform, а не имя. Указывайте `device-id` из
`flutter devices` либо подстроку имени, напр. `-d iphone`.

## Важно для симулятора (arm64)

Сборка под arm64-симулятор чувствительна к нативным зависимостям и Podfile:

- **`mobile_scanner` несовместим** с arm64-симулятором (MLKit) — на время прогона
  в симуляторе он должен быть исключён из `pubspec.yaml`.
- В `ios/Podfile` **не должно быть** самописного `post_install` с
  `BUILD_LIBRARY_FOR_DISTRIBUTION` — иначе сборка падает.
- Если симулятор «застрял» — `flutter clean && flutter pub get`, затем
  `cd ios && pod install`.

## Полезное

```bash
flutter devices                        # только booted-устройства/симуляторы
xcrun simctl list devices              # ВСЕ iOS-симуляторы и их состояние
xcrun simctl boot <device-id>          # загрузить симулятор
xcrun simctl bootstatus <device-id>    # дождаться готовности
xcrun simctl shutdown <device-id>      # выключить симулятор
```
