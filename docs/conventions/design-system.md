# Дизайн-система ChekiPrices

Источник истины по UI. Перед версткой экранов читай этот файл и используй каталог
компонентов из `app/lib/shared/components/`. Полный дизайн — `../superpowers/specs/2026-06-09-design-system-design.md`.

## Принцип

Material 3 + собственный бренд: стоковые M3-виджеты, единый слой токенов и тонкий
каталог компонентов. Светлая и тёмная темы из одного seed-цвета.

## Токены (`app/lib/core/theme/`)

- **Цвета:** палитра — `ColorScheme.fromSeed(AppColors.seed)` (seed `#2E7D5B`).
  Семантические бренд-цвета — в `AppTokens`: `success`, `warning`, `priceUp`, `priceDown`.
- **Типографика:** Inter через `AppTypography` (google_fonts).
- **Размеры/прочее:** `AppTokens` (ThemeExtension): spacing (`spaceXs..spaceXxl` = 4/8/12/16/24/32),
  radii (`radiusSm/Md/Lg/Pill` = 8/12/16/999), durations (`durationFast/Normal`).
- **Доступ:** `context.tokens.spaceMd`, `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`.

## Каталог компонентов (`app/lib/shared/components/`)

Импорт: `import 'package:ticket_app/shared/components/components.dart';`

| Компонент | Назначение |
|---|---|
| `AppButton` | Кнопка; варианты `primary/secondary/text/destructive`, `loading`, `icon`, `expanded`. |
| `AppTextField` | Поле ввода; `label`, `errorText`, `prefixIcon`, `obscureText`. |
| `AppCard` | Карточка-контейнер; опционально `onTap`. |
| `AppListTile` | Строка списка; `title/subtitle/leading/trailing/onTap`. |
| `AppChip` | Фильтр-чип; `selected`, `onSelected`. |
| `AppBadge` | Бейдж-статус; `tone` (`neutral/success/warning/error`). |
| `AppScaffold` | Каркас экрана; `title`, `body`, `actions`, `floatingActionButton`. |
| `AppLoader` | Индикатор загрузки. |
| `AppEmptyState` | Пустое состояние; `message`, `icon`. |
| `AppErrorView` | Ошибка; `message`, `onRetry`. |
| `MoneyText` | Сумма по валюте/локали (доменный). |
| `PriceDeltaText` | Изменение цены ↑/↓ цветом (доменный). |

## Правила (ОБЯЗАТЕЛЬНО)

1. В `lib/features/**` UI-примитивы — **только из каталога** (`AppButton`, `AppTextField`,
   `AppCard`, `AppListTile`, `AppChip`, `AppBadge`, …). Прямые `ElevatedButton`/`FilledButton`/
   `TextButton`/`OutlinedButton`/`TextField`/`Card`/`ListTile`/`Chip` — запрещены.
2. Стоковый Material — только для разметки (`Row/Column/Stack/Padding/Expanded/SizedBox/
   ListView/GridView/...`); каркас экрана — `AppScaffold`.
3. **Никакого хардкода** цвета/типографики/отступов/радиусов — только токены. Запрещены
   `Colors.*`, `Color(0x..)`, сырые `TextStyle(`, магические числа отступов/радиусов.
4. Новый компонент — **только в `shared/components/`** и только при повторе паттерна
   (≥2 использований); одноразовый UI — композиция существующих.
5. Компонент обязан работать в светлой и тёмной теме.

## Расширение каталога

Новый компонент: файл в `shared/components/` с dartdoc-шапкой, реэкспорт в `components.dart`,
widget-тест (рендер + работа в обеих темах), обновление таблицы выше.
