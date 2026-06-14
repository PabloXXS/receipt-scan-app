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
| `AppSkeleton` | Скелетон-загрузка; пульсирующий плейсхолдер. `height` обязательно, `width` null = max, `shape` = circle для аватара. |
| `AppEmptyState` | Пустое состояние; `message`, `icon`. |
| `AppErrorView` | Ошибка; `message`, `onRetry`. |
| `MoneyText` | Сумма по валюте/локали (доменный). |
| `PriceDeltaText` | Изменение цены ↑/↓ цветом (доменный). |

## Карта выбора компонента (ОБЯЗАТЕЛЬНО для Claude и людей)

Перед вёрсткой любого UI найди потребность в таблице и возьми указанный компонент.
**Не придумывай новые компоненты и не верстай локальные аналоги каталога в фичах.**

### Потребность → компонент каталога

| Нужно | Используй | Запрещённый аналог |
|---|---|---|
| Любая кнопка (CTA, второстепенная, текстовая, опасная) | `AppButton` (`variant`, `loading`, `icon`, `expanded`) | `ElevatedButton`, `FilledButton`, `TextButton`, `OutlinedButton` |
| Поле ввода (текст, пароль, e-mail, число) | `AppTextField` | `TextField`, `TextFormField` |
| Карточка-контейнер (в т.ч. кликабельная) | `AppCard` | `Card`, `InkWell`+`Container` |
| Строка списка | `AppListTile` | `ListTile` |
| Фильтр/переключаемый чип | `AppChip` | `Chip`, `FilterChip`, `ChoiceChip`, `ActionChip` |
| Статусная метка (успех/предупреждение/ошибка) | `AppBadge` (`tone`) | `Badge`, самодельный `Container` с цветом |
| Каркас экрана (AppBar, SafeArea, FAB) | `AppScaffold` | голый `Scaffold`+`AppBar` |
| Индикатор загрузки экрана/блока | `AppLoader` | `CircularProgressIndicator` напрямую |
| Скелетон-плейсхолдер части экрана | `AppSkeleton` | самодельный `Container` с анимацией |
| Пустое состояние («ничего нет») | `AppEmptyState` | самодельная колонка с иконкой |
| Состояние ошибки с повтором | `AppErrorView` (`onRetry`) | самодельная колонка с кнопкой |
| Денежная сумма | `MoneyText` | ручной `NumberFormat` в фиче |
| Изменение цены (рост/падение) | `PriceDeltaText` | ручное форматирование с цветом |

### Разрешённый стоковый Material 3 (обёртки пока нет)

Эти виджеты можно использовать напрямую — тема стилизует их сама; цвета/отступы
только из токенов:

- **Уведомления:** `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))`.
- **Диалоги:** `showDialog` + `AlertDialog`; **шторки:** `showModalBottomSheet`.
- **Переключатели форм:** `Switch`, `Checkbox`, `Radio`, `Slider`.
- **Навигация:** `NavigationBar`, `TabBar` (когда появится shell-навигация).
- **Прочее:** `Icon`, `Text` (стиль только из `textTheme`), `Divider`,
  `RefreshIndicator`, `Tooltip`.
- **Разметка:** `Row/Column/Stack/Padding/Expanded/SizedBox/ListView/GridView/...` —
  без ограничений, отступы из токенов.

⚠️ Не используй `*.adaptive`-конструкторы (`Switch.adaptive` и т.п.) — привязка к
платформенным эвристикам Flutter хрупка при грядущем выносе Material из SDK.

### Если компонента нет в карте

1. **Сначала** собери UI композицией существующих компонентов + разметка.
2. Если нужен интерактивный примитив из списка «разрешённый стоковый M3» — бери
   стоковый, стилизуя только токенами.
3. Если паттерн повторяется (≥2 экранов) — заведи компонент в `shared/components/`
   по чек-листу из раздела «Расширение каталога» и добавь строку в карту выше.
4. **Никогда** не создавай в `lib/features/**` приватный виджет, дублирующий
   назначение компонента каталога (свой button/card/badge/loader и т.д.).

## Правила (ОБЯЗАТЕЛЬНО)

1. В `lib/features/**` UI-примитивы — **только из каталога** по карте выше. Прямые
   `ElevatedButton`/`FilledButton`/`TextButton`/`OutlinedButton`/`TextField`/`Card`/
   `ListTile`/`Chip` — запрещены.
2. Стоковый Material — только из списка «разрешённый стоковый M3» и разметка;
   каркас экрана — `AppScaffold`.
3. **Никакого хардкода** цвета/типографики/отступов/радиусов — только токены. Запрещены
   `Colors.*`, `Color(0x..)`, сырые `TextStyle(`, магические числа отступов/радиусов.
4. Новый компонент — **только в `shared/components/`** и только при повторе паттерна
   (≥2 использований); одноразовый UI — композиция существующих.
5. Компонент обязан работать в светлой и тёмной теме.

## Расширение каталога

Новый компонент: файл в `shared/components/` с dartdoc-шапкой, реэкспорт в `components.dart`,
widget-тест (рендер + работа в обеих темах), обновление таблицы выше.
