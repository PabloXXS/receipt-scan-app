# OCR-сервис: магазин-агностичный парсер позиций — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Построить Python OCR-сервис, который по фото чека возвращает распознанные позиции, с магазин-агностичным парсером (геометрия + арифметика + классы лексем) в основе.

**Architecture:** Сервис из трёх изолированных слоёв: (1) **чистый парсер** `Observation[] → ParsedReceipt` (без сети/тяжёлых зависимостей, тестируется локально на фикстурах); (2) **PaddleOCR-адаптер** фото → `Observation[]` (тяжёлый, проверяется в Docker/CI); (3) **FastAPI** `POST /ocr`. Это план №1 из 4 (парсер+сервис; далее — миграция БД, тонкий PHP-воркер, клиент Flutter).

**Tech Stack:** Python 3.12, pytest, FastAPI, uvicorn, **PaddleOCR 2.x** (`lang="cyrillic"`, PP-OCRv4 cyrillic; paddlepaddle 2.6, numpy<2), Pillow/numpy для препроцессинга, Docker. (Апгрейд на 3.x/PP-OCRv5 — будущий шаг.)

**Локальное окружение:** python3/pip есть; Docker НЕТ. Шаги парсера (Tasks 1–9) гоняются локально через pytest. PaddleOCR-адаптер и Docker (Tasks 10–12) собираются/проверяются в CI — локальный прогон не требуется, тесты этих слоёв используют моки.

---

## Структура файлов

```
ocr-service/
  requirements.txt              # FastAPI, uvicorn, numpy, Pillow (рантайм)
  requirements-ocr.txt          # paddleocr, paddlepaddle (тяжёлое, только Docker)
  requirements-dev.txt          # pytest
  pyproject.toml                # пакет ocr_service, конфиг pytest
  Dockerfile
  README.md
  src/ocr_service/
    __init__.py
    models.py                   # Observation, ParsedItem, ParsedReceipt
    parser/
      __init__.py               # экспорт parse()
      rows.py                   # кластеризация по y → строки
      columns.py                # денежная колонка, x-кластеризация
      roles.py                  # инференс ролей цена/кол-во/сумма (a*b≈c)
      names.py                  # склейка многострочных названий
      region.py                 # границы зоны позиций + якорь итога
      reconcile.py              # confidence + сверка с итогом
      parse.py                  # оркестрация stage'ей
    ocr/
      __init__.py
      paddle_adapter.py         # PaddleOCR → Observation[] (Docker/CI)
      preprocess.py             # grayscale/дескью/бинаризация/апскейл
    api/
      __init__.py
      main.py                   # FastAPI POST /ocr
  tests/
    __init__.py
    fixtures/
      __init__.py
      prostore.py               # Observation[] с геометрией (реальная раскладка)
    test_models.py
    test_rows.py
    test_columns.py
    test_roles.py
    test_names.py
    test_region.py
    test_reconcile.py
    test_parse.py
    test_api.py
```

**Соглашение о координатах:** `bbox = (x, y, w, h)` в пикселях, начало координат — **верх-лево**, `x` растёт вправо, `y` растёт вниз. (PaddleOCR отдаёт полигоны сверху-вниз; адаптер нормализует в этот вид — см. Task 10.)

---

### Task 0: Скелет проекта ocr-service

**Files:**
- Create: `ocr-service/pyproject.toml`
- Create: `ocr-service/requirements.txt`
- Create: `ocr-service/requirements-dev.txt`
- Create: `ocr-service/requirements-ocr.txt`
- Create: `ocr-service/src/ocr_service/__init__.py` (пустой)
- Create: `ocr-service/src/ocr_service/parser/__init__.py` (пустой пока)
- Create: `ocr-service/tests/__init__.py` (пустой)
- Create: `ocr-service/tests/fixtures/__init__.py` (пустой)

- [ ] **Step 1: Создать pyproject.toml**

```toml
[build-system]
requires = ["setuptools>=68"]
build-backend = "setuptools.build_meta"

[project]
name = "ocr-service"
version = "0.1.0"
requires-python = ">=3.12"

[tool.setuptools.packages.find]
where = ["src"]

[tool.pytest.ini_options]
pythonpath = ["src"]
testpaths = ["tests"]
```

- [ ] **Step 2: Создать requirements-файлы**

`requirements.txt`:
```
fastapi==0.115.*
uvicorn[standard]==0.32.*
numpy==2.*
Pillow==11.*
python-multipart==0.0.*
```

`requirements-dev.txt`:
```
-r requirements.txt
pytest==8.*
httpx==0.27.*
```

`requirements-ocr.txt` (тяжёлое, ставится только в Docker):
```
paddleocr==2.9.*
paddlepaddle==3.0.*
```

- [ ] **Step 3: Создать пустые `__init__.py`**

Создать `src/ocr_service/__init__.py`, `src/ocr_service/parser/__init__.py`, `tests/__init__.py`, `tests/fixtures/__init__.py` — все пустые.

- [ ] **Step 4: Установить dev-зависимости и проверить pytest**

Run: `cd ocr-service && python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt && pip install -e .`
Expected: установка без ошибок.

Run: `cd ocr-service && . .venv/bin/activate && pytest -q`
Expected: `no tests ran` (тестов ещё нет) — без ошибок импорта.

- [ ] **Step 5: Commit**

```bash
git add ocr-service/
git commit -m "chore(ocr): skeleton of python ocr-service"
```

---

### Task 1: Доменные модели (Observation, ParsedItem, ParsedReceipt)

**Files:**
- Create: `ocr-service/src/ocr_service/models.py`
- Test: `ocr-service/tests/test_models.py`

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_models.py
from ocr_service.models import Observation, ParsedItem, ParsedReceipt


def test_observation_right_edge_and_center():
    obs = Observation(text="5.49", bbox=(100, 200, 40, 12), confidence=0.9)
    assert obs.right == 140
    assert obs.cx == 120
    assert obs.cy == 206


def test_parsed_receipt_items_sum():
    r = ParsedReceipt(
        items=[
            ParsedItem(raw_name="A", qty=1, unit_price=2.0, sum=2.0, confidence=0.9),
            ParsedItem(raw_name="B", qty=2, unit_price=1.5, sum=3.0, confidence=0.8),
        ],
        total=5.0,
        confidence=0.85,
    )
    assert r.items_sum == 5.0
```

- [ ] **Step 2: Запустить тест — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_models.py -v`
Expected: FAIL — `ModuleNotFoundError: ocr_service.models`.

- [ ] **Step 3: Реализовать модели**

```python
# src/ocr_service/models.py
"""Доменные модели OCR-сервиса: наблюдение OCR и распознанный чек."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Observation:
    """Одно текстовое наблюдение OCR с геометрией. bbox=(x,y,w,h), origin top-left."""

    text: str
    bbox: tuple[float, float, float, float]
    confidence: float

    @property
    def x(self) -> float:
        return self.bbox[0]

    @property
    def y(self) -> float:
        return self.bbox[1]

    @property
    def w(self) -> float:
        return self.bbox[2]

    @property
    def h(self) -> float:
        return self.bbox[3]

    @property
    def right(self) -> float:
        return self.bbox[0] + self.bbox[2]

    @property
    def cx(self) -> float:
        return self.bbox[0] + self.bbox[2] / 2

    @property
    def cy(self) -> float:
        return self.bbox[1] + self.bbox[3] / 2


@dataclass(frozen=True)
class ParsedItem:
    """Распознанная позиция чека."""

    raw_name: str
    qty: float
    unit_price: float
    sum: float
    confidence: float
    barcode: str | None = None


@dataclass(frozen=True)
class ParsedReceipt:
    """Результат разбора чека."""

    items: list[ParsedItem] = field(default_factory=list)
    total: float | None = None
    confidence: float = 0.0

    @property
    def items_sum(self) -> float:
        return round(sum(i.sum for i in self.items), 2)
```

- [ ] **Step 4: Запустить тест — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_models.py -v`
Expected: PASS (2 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/models.py ocr-service/tests/test_models.py
git commit -m "feat(ocr): domain models Observation/ParsedItem/ParsedReceipt"
```

---

### Task 2: Фикстура геометрии реального чека (ProStore)

**Files:**
- Create: `ocr-service/tests/fixtures/prostore.py`

Фикстура воспроизводит раскладку чека ProStore (по `app/test/.../prostore_ocr_fixture.dart`),
но с координатами. Колонки: название слева (`x≈40`), денежные колонки справа
(`цена x≈300`, `кол-во x≈420`, `сумма x≈520`). Шаг строки по `y` ≈ 30.

- [ ] **Step 1: Создать фикстуру**

```python
# tests/fixtures/prostore.py
"""Геометрическая фикстура чека ProStore для тестов парсера."""
from ocr_service.models import Observation

C = 0.9  # типовая уверенность OCR


def _o(text, x, y, w=120, h=18):
    return Observation(text=text, bbox=(x, y, w, h), confidence=C)


# Координаты подобраны так, чтобы: названия выровнены по x≈40,
# суммы правоприжаты к x≈520, цена≈300, кол-во≈420.
PROSTORE: list[Observation] = [
    # шапка
    _o("ProStore", 40, 20, 100),
    _o('Гипермаркет "ProStore" Малиновка', 40, 50, 360),
    _o("УНП 193854962  РН СККО 119093043", 40, 80, 320),
    _o("Цена Кол-во Итого", 300, 110, 240),
    # позиция 1: простая, qty=1, название в 2 строки
    _o("5449000131843 Напиток Coca-Cola без сахара", 40, 150, 380),
    _o("безалк газ 2л ПЭТ", 60, 178, 160),
    _o("5.49", 300, 200, 44), _o("*1.000", 410, 200, 60), _o("5.49", 516, 200, 44),
    # позиция 2: простая, qty=1
    _o("4680021880490 Печенье сдобное Американское 200г", 40, 240, 420),
    _o("3.64", 300, 268, 44), _o("*1.000", 410, 268, 60), _o("3.64", 516, 268, 44),
    # позиция 3: весовая, qty=0.562
    _o("2240748 Рулет Праздничный к/в в/с Петруха", 40, 308, 380),
    _o("флоупак вес 1кг Юнимит", 60, 336, 200),
    _o("15.77", 296, 358, 50), _o("*0.562", 410, 358, 60), _o("8.86", 516, 358, 44),
    # позиция 4: весовая без отдельной строки названия
    _o("2204091 Фарш говяжий полуфабрикат вес", 40, 398, 360),
    _o("21.99", 296, 426, 50), _o("*0.488", 410, 426, 60), _o("10.73", 510, 426, 50),
    # подвал
    _o("ИТОГО К ОПЛАТЕ", 40, 470, 200), _o("28.72", 516, 470, 44),
    _o("Банк. пл. картой:", 40, 500, 160), _o("28.72", 516, 500, 44),
    _o("Кассир: Пинчукова Л.М. 10.06.2026 14:08:18", 40, 530, 380),
]

# Ожидаемые позиции (для интеграционного теста parse):
# Coca-Cola 5.49×1=5.49; Печенье 3.64×1=3.64; Рулет 15.77×0.562=8.86;
# Фарш 21.99×0.488=10.73. Сумма = 28.72 == ИТОГО.
```

- [ ] **Step 2: Проверить, что фикстура импортируется**

Run: `cd ocr-service && . .venv/bin/activate && python -c "from tests.fixtures.prostore import PROSTORE; print(len(PROSTORE))"`
Expected: печатает число наблюдений (без ошибок импорта).

- [ ] **Step 3: Commit**

```bash
git add ocr-service/tests/fixtures/prostore.py
git commit -m "test(ocr): geometric fixture of ProStore receipt"
```

---

### Task 3: Сборка строк (rows) — кластеризация по y

**Files:**
- Create: `ocr-service/src/ocr_service/parser/rows.py`
- Test: `ocr-service/tests/test_rows.py`

Строка — группа наблюдений, чьи центры по `y` лежат в пределах половины медианной
высоты. Внутри строки — сортировка по `x`.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_rows.py
from ocr_service.models import Observation
from ocr_service.parser.rows import group_rows


def _o(text, x, y, w=40, h=18):
    return Observation(text=text, bbox=(x, y, w, h), confidence=0.9)


def test_groups_same_line_and_sorts_by_x():
    obs = [_o("B", 200, 100), _o("A", 40, 102), _o("C", 400, 99)]
    rows = group_rows(obs)
    assert len(rows) == 1
    assert [o.text for o in rows[0]] == ["A", "B", "C"]


def test_separates_distinct_lines_top_to_bottom():
    obs = [_o("line2", 40, 140), _o("line1", 40, 100)]
    rows = group_rows(obs)
    assert [r[0].text for r in rows] == ["line1", "line2"]
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_rows.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/rows.py
"""Группировка наблюдений в визуальные строки по вертикали (y)."""
from __future__ import annotations

from statistics import median

from ocr_service.models import Observation


def group_rows(observations: list[Observation]) -> list[list[Observation]]:
    """Возвращает строки сверху вниз; внутри строки — наблюдения слева направо."""
    if not observations:
        return []
    heights = [o.h for o in observations if o.h > 0] or [1.0]
    tol = median(heights) / 2
    ordered = sorted(observations, key=lambda o: o.cy)
    rows: list[list[Observation]] = []
    current: list[Observation] = [ordered[0]]
    anchor = ordered[0].cy
    for o in ordered[1:]:
        if abs(o.cy - anchor) <= tol:
            current.append(o)
        else:
            rows.append(current)
            current = [o]
            anchor = o.cy
    rows.append(current)
    for r in rows:
        r.sort(key=lambda o: o.x)
    return rows
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_rows.py -v`
Expected: PASS (2 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/rows.py ocr-service/tests/test_rows.py
git commit -m "feat(ocr): row grouping by vertical clustering"
```

---

### Task 4: Денежные токены и колонки (columns)

**Files:**
- Create: `ocr-service/src/ocr_service/parser/columns.py`
- Test: `ocr-service/tests/test_columns.py`

Денежный токен — текст, матчащий `^\d+[.,]\d{2}$` (после очистки от пробелов).
Разделитель кол-ва (`*`, `x`, `х`, `·`) очищается. Денежная колонка — кластер денежных
токенов с наибольшим средним `right` (правоприжатость).

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_columns.py
from ocr_service.models import Observation
from ocr_service.parser.columns import money_value, is_money, money_column_x


def _o(text, x, y, w=44, h=18):
    return Observation(text=text, bbox=(x, y, w, h), confidence=0.9)


def test_money_value_handles_comma_and_dot():
    assert money_value("5,49") == 5.49
    assert money_value("15.77") == 15.77
    assert money_value("*1.000") is None  # это кол-во, не сумма (3 знака)
    assert money_value("abc") is None


def test_is_money_two_decimals_only():
    assert is_money("5.49") is True
    assert is_money("1.000") is False


def test_money_column_x_picks_rightmost_cluster():
    obs = [
        _o("5.49", 300, 100), _o("5.49", 516, 100),
        _o("3.64", 300, 140), _o("3.64", 516, 140),
    ]
    # правый кластер сумм центрируется около x≈538
    x = money_column_x(obs)
    assert 520 <= x <= 560
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_columns.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/columns.py
"""Денежные токены и определение денежной колонки по геометрии."""
from __future__ import annotations

import re

from ocr_service.models import Observation

_MONEY = re.compile(r"^\d+[.,]\d{2}$")


def is_money(text: str) -> bool:
    """Денежный токен: целое.два знака (ровно 2 десятичных)."""
    return bool(_MONEY.match(text.strip()))


def money_value(text: str) -> float | None:
    """Числовое значение денежного токена либо None."""
    t = text.strip()
    if not is_money(t):
        return None
    return float(t.replace(",", "."))


def money_column_x(observations: list[Observation]) -> float | None:
    """Центр x самого правого кластера денежных токенов (колонка сумм)."""
    money = [o for o in observations if is_money(o.text)]
    if not money:
        return None
    # кластеризуем по cx с порогом, берём кластер с максимальным средним right
    money.sort(key=lambda o: o.cx)
    clusters: list[list[Observation]] = [[money[0]]]
    for o in money[1:]:
        if o.cx - clusters[-1][-1].cx <= 60:
            clusters[-1].append(o)
        else:
            clusters.append([o])
    best = max(clusters, key=lambda c: sum(o.right for o in c) / len(c))
    return sum(o.cx for o in best) / len(best)
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_columns.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/columns.py ocr-service/tests/test_columns.py
git commit -m "feat(ocr): money token detection and money-column geometry"
```

---

### Task 5: Инференс ролей цена/кол-во/сумма (roles)

**Files:**
- Create: `ocr-service/src/ocr_service/parser/roles.py`
- Test: `ocr-service/tests/test_roles.py`

Из числовых токенов строки (цена, кол-во, сумма в любом порядке) выбираем тройку
`(unit, qty, sum)` так, чтобы `unit*qty ≈ sum`. Кол-во может иметь 3 знака
(`*1.000`, `*0.562`); сумма — денежный токен (2 знака) в денежной колонке.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_roles.py
from ocr_service.models import Observation
from ocr_service.parser.roles import infer_price_qty_sum


def _o(text, x, y=100, w=44, h=18):
    return Observation(text=text, bbox=(x, y, w, h), confidence=0.9)


def test_simple_qty_one():
    row = [_o("5.49", 300), _o("*1.000", 410), _o("5.49", 516)]
    res = infer_price_qty_sum(row, money_col_x=538)
    assert res == (5.49, 1.0, 5.49)


def test_weighted_item():
    row = [_o("15.77", 296), _o("*0.562", 410), _o("8.86", 516)]
    res = infer_price_qty_sum(row, money_col_x=538)
    assert res == (15.77, 0.562, 8.86)


def test_only_sum_present_defaults_qty_one():
    row = [_o("3.64", 516)]
    res = infer_price_qty_sum(row, money_col_x=538)
    assert res == (3.64, 1.0, 3.64)


def test_no_numbers_returns_none():
    res = infer_price_qty_sum([_o("Хлеб", 40)], money_col_x=538)
    assert res is None
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_roles.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/roles.py
"""Инференс ролей цена/кол-во/сумма из чисел строки по арифметике a*b≈c."""
from __future__ import annotations

import re
from itertools import permutations

from ocr_service.models import Observation
from ocr_service.parser.columns import is_money, money_value

_NUM = re.compile(r"\d+[.,]\d+|\d+")


def _to_float(text: str) -> float | None:
    m = _NUM.search(text.replace(",", "."))
    return float(m.group()) if m else None


def _numbers(row: list[Observation]) -> list[tuple[float, Observation]]:
    out: list[tuple[float, Observation]] = []
    for o in row:
        v = _to_float(o.text)
        if v is not None:
            out.append((v, o))
    return out


def infer_price_qty_sum(
    row: list[Observation], money_col_x: float | None, tol: float = 0.02
) -> tuple[float, float, float] | None:
    """Возвращает (unit, qty, sum) либо None, если чисел нет."""
    nums = _numbers(row)
    if not nums:
        return None

    # сумма — денежный токен ближе всего к денежной колонке
    money = [(v, o) for v, o in nums if is_money(o.text)]
    if money and money_col_x is not None:
        s_val, s_obs = min(money, key=lambda t: abs(t[1].cx - money_col_x))
    elif money:
        s_val, s_obs = money[-1]
    else:
        # нет денежного токена с 2 знаками — берём правейшее число как сумму
        s_val, s_obs = max(nums, key=lambda t: t[1].cx)

    rest = [v for v, o in nums if o is not s_obs]
    if not rest:
        return (round(s_val, 2), 1.0, round(s_val, 2))

    # ищем (unit, qty) среди rest, чтобы unit*qty ≈ sum
    best: tuple[float, float] | None = None
    best_err = tol
    for a, b in permutations(rest, 2) if len(rest) >= 2 else [(rest[0], 1.0)]:
        if abs(a * b - s_val) <= max(best_err, tol) and a * b != 0:
            err = abs(a * b - s_val)
            if best is None or err < best_err:
                best, best_err = (a, b), err
    if best is None:
        # одно число рядом — это либо цена (qty=1), либо кол-во
        only = rest[0]
        if abs(only - s_val) <= tol:
            return (round(s_val, 2), 1.0, round(s_val, 2))
        # трактуем как цену, qty выводим
        qty = round(s_val / only, 3) if only else 1.0
        return (round(only, 2), qty, round(s_val, 2))
    unit, qty = best
    return (round(unit, 2), round(qty, 3), round(s_val, 2))
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_roles.py -v`
Expected: PASS (4 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/roles.py ocr-service/tests/test_roles.py
git commit -m "feat(ocr): arithmetic role inference for price/qty/sum"
```

---

### Task 6: Границы зоны позиций и якорь итога (region)

**Files:**
- Create: `ocr-service/src/ocr_service/parser/region.py`
- Test: `ocr-service/tests/test_region.py`

Зона позиций = строки, у которых есть денежный токен в денежной колонке И алфавитное
название слева от неё. Итог = наибольшее денежное значение в строках НИЖЕ зоны позиций
(подвал). Без словаря ключевых слов.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_region.py
from ocr_service.parser.rows import group_rows
from ocr_service.parser.columns import money_column_x
from ocr_service.parser.region import split_region
from tests.fixtures.prostore import PROSTORE


def test_splits_items_and_footer_total():
    rows = group_rows(PROSTORE)
    col = money_column_x(PROSTORE)
    item_rows, total = split_region(rows, col)
    # 4 позиции: каждая начинается строкой названия с суммой ниже
    # item_rows — строки с денежным токеном в зоне позиций
    assert total == 28.72
    # последняя строка зоны позиций — не подвал (ИТОГО/Банк/Кассир исключены)
    texts = " ".join(o.text for r in item_rows for o in r)
    assert "Кассир" not in texts
    assert "Банк" not in texts
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_region.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/region.py
"""Границы зоны позиций и языконезависимый якорь итога."""
from __future__ import annotations

from ocr_service.models import Observation
from ocr_service.parser.columns import is_money, money_value

_LETTERS = tuple("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя"
                 "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")


def _has_letters(row: list[Observation]) -> bool:
    return any(any(ch in _LETTERS for ch in o.text) for o in row)


def _row_money(row: list[Observation], money_col_x: float | None) -> float | None:
    cands = [o for o in row if is_money(o.text)]
    if not cands:
        return None
    if money_col_x is not None:
        o = min(cands, key=lambda o: abs(o.cx - money_col_x))
        if abs(o.cx - money_col_x) > 80:
            return None
        return money_value(o.text)
    return money_value(cands[-1].text)


def split_region(
    rows: list[list[Observation]], money_col_x: float | None
) -> tuple[list[list[Observation]], float | None]:
    """Делит строки на (зона позиций, итог). Итог — максимум сумм в подвале."""
    # зона позиций: непрерывная полоса строк, где есть сумма в денежной колонке
    item_rows: list[list[Observation]] = []
    last_item_idx = -1
    for idx, row in enumerate(rows):
        if _row_money(row, money_col_x) is not None and _has_letters_left(row, money_col_x):
            item_rows.append(row)
            last_item_idx = idx
    # подвал — строки ниже последней позиции
    footer = rows[last_item_idx + 1:] if last_item_idx >= 0 else []
    totals = [
        _row_money(r, money_col_x)
        for r in footer
        if _row_money(r, money_col_x) is not None
    ]
    total = max(totals) if totals else None
    return item_rows, total


def _has_letters_left(row: list[Observation], money_col_x: float | None) -> bool:
    if money_col_x is None:
        return _has_letters(row)
    left = [o for o in row if o.cx < money_col_x - 40]
    return _has_letters(left)
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_region.py -v`
Expected: PASS (1 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/region.py ocr-service/tests/test_region.py
git commit -m "feat(ocr): item-region boundaries and language-independent total anchor"
```

---

### Task 7: Склейка многострочных названий (names)

**Files:**
- Create: `ocr-service/src/ocr_service/parser/names.py`
- Test: `ocr-service/tests/test_names.py`

Название позиции = алфавитный текст слева от денежной колонки в строке позиции +
строки-продолжения (без денежного токена, выровненные под колонкой названия) между
заголовком позиции и её строкой суммы. Длинные цифровые коды в начале — отдельно как
`barcode`.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_names.py
from ocr_service.parser.names import extract_name_and_barcode


def test_strips_leading_barcode():
    name, code = extract_name_and_barcode("5449000131843 Напиток Coca-Cola без сахара")
    assert code == "5449000131843"
    assert name == "Напиток Coca-Cola без сахара"


def test_no_barcode():
    name, code = extract_name_and_barcode("Хлеб Бородинский")
    assert code is None
    assert name == "Хлеб Бородинский"


def test_short_number_is_not_barcode():
    name, code = extract_name_and_barcode("2 шт Молоко")
    assert code is None
    assert name == "2 шт Молоко"
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_names.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/names.py
"""Извлечение названия и штрихкода; склейка переносов названия."""
from __future__ import annotations

import re

from ocr_service.models import Observation
from ocr_service.parser.columns import is_money

_BARCODE = re.compile(r"^\s*(?:\[[^\]]*\]\s*)?(\d{6,})\s+(.+)$")
_LETTER = re.compile(r"[A-Za-zА-Яа-яЁё]")


def extract_name_and_barcode(text: str) -> tuple[str, str | None]:
    """Отделяет ведущий штрихкод (6+ цифр) от названия, если за ним идёт текст с буквами."""
    m = _BARCODE.match(text)
    if m and _LETTER.search(m.group(2)):
        return m.group(2).strip(), m.group(1)
    return text.strip(), None


def name_text_of_row(row: list[Observation], money_col_x: float | None) -> str:
    """Конкатенация алфавитных токенов строки слева от денежной колонки."""
    parts = []
    for o in row:
        if money_col_x is not None and o.cx >= money_col_x - 40:
            continue
        if is_money(o.text):
            continue
        parts.append(o.text)
    return " ".join(parts).strip()


def is_name_continuation(row: list[Observation], money_col_x: float | None) -> bool:
    """Строка-продолжение названия: есть буквы, нет денежного токена в колонке сумм."""
    has_money = any(
        is_money(o.text)
        and (money_col_x is None or abs(o.cx - money_col_x) <= 80)
        for o in row
    )
    has_letters = any(_LETTER.search(o.text) for o in row)
    return has_letters and not has_money
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_names.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/names.py ocr-service/tests/test_names.py
git commit -m "feat(ocr): name/barcode extraction and continuation detection"
```

---

### Task 8: Сверка и confidence (reconcile)

**Files:**
- Create: `ocr-service/src/ocr_service/parser/reconcile.py`
- Test: `ocr-service/tests/test_reconcile.py`

Confidence чека = среднее по позициям, скорректированное на сверку: если `items_sum`
совпал с `total` (±0.02) — бонус; разошёлся — штраф. Confidence позиции учитывает
выполнение `unit*qty≈sum`.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_reconcile.py
from ocr_service.parser.reconcile import item_confidence, receipt_confidence


def test_item_confidence_high_when_arithmetic_holds():
    assert item_confidence(ocr_conf=0.9, unit=5.49, qty=1.0, sum_=5.49) > 0.85


def test_item_confidence_drops_when_arithmetic_breaks():
    low = item_confidence(ocr_conf=0.9, unit=5.49, qty=1.0, sum_=9.99)
    assert low < 0.6


def test_receipt_confidence_bonus_on_total_match():
    matched = receipt_confidence(item_confs=[0.9, 0.9], items_sum=10.0, total=10.0)
    mismatched = receipt_confidence(item_confs=[0.9, 0.9], items_sum=10.0, total=12.0)
    assert matched > mismatched
    assert matched >= 0.9
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_reconcile.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать**

```python
# src/ocr_service/parser/reconcile.py
"""Confidence позиций и чека + сверка суммы позиций с итогом."""
from __future__ import annotations


def item_confidence(ocr_conf: float, unit: float, qty: float, sum_: float) -> float:
    """Уверенность позиции: OCR-уверенность, скорректированная на арифметику."""
    arith_ok = abs(unit * qty - sum_) <= 0.02
    base = max(0.0, min(1.0, ocr_conf))
    return round(base if arith_ok else base * 0.5, 3)


def receipt_confidence(
    item_confs: list[float], items_sum: float, total: float | None
) -> float:
    """Уверенность чека: среднее по позициям + бонус/штраф за сверку с итогом."""
    if not item_confs:
        return 0.0
    avg = sum(item_confs) / len(item_confs)
    if total is None:
        return round(avg * 0.9, 3)
    if abs(items_sum - total) <= 0.02:
        return round(min(1.0, avg + 0.05), 3)
    return round(avg * 0.6, 3)
```

- [ ] **Step 4: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_reconcile.py -v`
Expected: PASS (3 passed).

- [ ] **Step 5: Commit**

```bash
git add ocr-service/src/ocr_service/parser/reconcile.py ocr-service/tests/test_reconcile.py
git commit -m "feat(ocr): item/receipt confidence and total reconciliation"
```

---

### Task 9: Оркестрация parse() + интеграционный тест на фикстуре

**Files:**
- Create: `ocr-service/src/ocr_service/parser/parse.py`
- Modify: `ocr-service/src/ocr_service/parser/__init__.py` (экспорт `parse`)
- Test: `ocr-service/tests/test_parse.py`

Собирает stage'и: строки → денежная колонка → зона/итог → для каждой позиции
(заголовок + продолжения до строки суммы) название/штрихкод + роли → confidence.

- [ ] **Step 1: Написать падающий тест**

```python
# tests/test_parse.py
from ocr_service.parser import parse
from tests.fixtures.prostore import PROSTORE


def test_parses_prostore_fixture():
    r = parse(PROSTORE)
    assert len(r.items) == 4
    names = [i.raw_name for i in r.items]
    assert any("Coca-Cola" in n for n in names)
    assert any("Рулет" in n for n in names)
    # весовая позиция распознана с дробным кол-вом
    rulet = next(i for i in r.items if "Рулет" in i.raw_name)
    assert rulet.qty == 0.562
    assert rulet.unit_price == 15.77
    assert rulet.sum == 8.86
    # сверка с итогом сошлась → высокая уверенность
    assert r.total == 28.72
    assert abs(r.items_sum - 28.72) <= 0.02
    assert r.confidence >= 0.9
    # штрихкод извлечён, в название не попал
    coke = next(i for i in r.items if "Coca-Cola" in i.raw_name)
    assert coke.barcode == "5449000131843"
    assert "5449000131843" not in coke.raw_name
```

- [ ] **Step 2: Запустить — убедиться, что падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_parse.py -v`
Expected: FAIL — `parse` не определён.

- [ ] **Step 3: Реализовать оркестрацию**

```python
# src/ocr_service/parser/parse.py
"""Оркестрация магазин-агностичного разбора: Observation[] → ParsedReceipt."""
from __future__ import annotations

from ocr_service.models import Observation, ParsedItem, ParsedReceipt
from ocr_service.parser.columns import money_column_x
from ocr_service.parser.names import (
    extract_name_and_barcode,
    is_name_continuation,
    name_text_of_row,
)
from ocr_service.parser.reconcile import item_confidence, receipt_confidence
from ocr_service.parser.region import split_region
from ocr_service.parser.roles import infer_price_qty_sum
from ocr_service.parser.rows import group_rows


def parse(observations: list[Observation]) -> ParsedReceipt:
    """Разбирает наблюдения OCR в чек, опираясь на геометрию и арифметику."""
    rows = group_rows(observations)
    col = money_column_x(observations)
    item_rows, total = split_region(rows, col)
    if not item_rows:
        return ParsedReceipt(items=[], total=total, confidence=0.0)

    # индексы строк-позиций в исходном порядке rows
    idx_of = {id(r): i for i, r in enumerate(rows)}
    items: list[ParsedItem] = []
    confs: list[float] = []

    for r in item_rows:
        roles = infer_price_qty_sum(r, col)
        if roles is None:
            continue
        unit, qty, s = roles
        # имя: текст этой строки + предыдущие строки-продолжения
        name_parts = [name_text_of_row(r, col)]
        ri = idx_of[id(r)]
        j = ri - 1
        while j >= 0 and rows[j] not in item_rows and is_name_continuation(rows[j], col):
            name_parts.insert(0, name_text_of_row(rows[j], col))
            j -= 1
        # следующие строки-продолжения (название перенесено вниз)
        k = ri + 1
        while k < len(rows) and rows[k] not in item_rows and is_name_continuation(rows[k], col):
            name_parts.append(name_text_of_row(rows[k], col))
            k += 1
        raw = " ".join(p for p in name_parts if p).strip()
        name, barcode = extract_name_and_barcode(raw)

        ocr_conf = sum(o.confidence for o in r) / len(r)
        conf = item_confidence(ocr_conf, unit, qty, s)
        confs.append(conf)
        items.append(
            ParsedItem(
                raw_name=name, qty=qty, unit_price=unit, sum=s,
                confidence=conf, barcode=barcode,
            )
        )

    items_sum = round(sum(i.sum for i in items), 2)
    confidence = receipt_confidence(confs, items_sum, total)
    return ParsedReceipt(items=items, total=total, confidence=confidence)
```

- [ ] **Step 4: Экспортировать parse из пакета**

```python
# src/ocr_service/parser/__init__.py
"""Магазин-агностичный парсер позиций чека."""
from ocr_service.parser.parse import parse

__all__ = ["parse"]
```

- [ ] **Step 5: Запустить — убедиться, что проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_parse.py -v`
Expected: PASS (1 passed).

Если падает на склейке названия/ролях — отладить на фикстуре, при необходимости
поправить пороги в `columns.money_column_x`/`region`/`roles` (НЕ добавляя правил под
ProStore — только универсальные пороги).

- [ ] **Step 6: Прогнать ВСЕ тесты парк ядра**

Run: `cd ocr-service && . .venv/bin/activate && pytest -q`
Expected: все тесты Tasks 1–9 PASS.

- [ ] **Step 7: Commit**

```bash
git add ocr-service/src/ocr_service/parser/parse.py ocr-service/src/ocr_service/parser/__init__.py ocr-service/tests/test_parse.py
git commit -m "feat(ocr): orchestrate store-agnostic receipt parsing"
```

---

### Task 10: PaddleOCR-адаптер + препроцессинг (Docker/CI)

**Files:**
- Create: `ocr-service/src/ocr_service/ocr/preprocess.py`
- Create: `ocr-service/src/ocr_service/ocr/paddle_adapter.py`
- Create: `ocr-service/src/ocr_service/ocr/__init__.py`
- Test: `ocr-service/tests/test_preprocess.py`

> PaddleOCR локально не ставим (нет Docker, тяжёлые веса). Тестируем **препроцессинг**
> (чистый, на numpy/Pillow — ставится локально) и **контракт адаптера через мок**.
> Реальный инференс проверяется в Docker/CI (Task 12).

- [ ] **Step 1: Тест препроцессинга**

```python
# tests/test_preprocess.py
import numpy as np
from ocr_service.ocr.preprocess import to_grayscale, normalize


def test_to_grayscale_reduces_channels():
    rgb = np.zeros((10, 10, 3), dtype=np.uint8)
    gray = to_grayscale(rgb)
    assert gray.ndim == 2


def test_normalize_returns_uint8():
    img = np.full((4, 4), 130, dtype=np.uint8)
    out = normalize(img)
    assert out.dtype == np.uint8
    assert out.shape == (4, 4)
```

- [ ] **Step 2: Запустить — падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_preprocess.py -v`
Expected: FAIL — модуль не найден.

- [ ] **Step 3: Реализовать препроцессинг**

```python
# src/ocr_service/ocr/preprocess.py
"""Препроцессинг фото чека: grayscale, нормализация контраста, апскейл."""
from __future__ import annotations

import numpy as np
from PIL import Image


def to_grayscale(img: np.ndarray) -> np.ndarray:
    """RGB→серый (или возврат как есть для 2D)."""
    if img.ndim == 2:
        return img
    return np.asarray(Image.fromarray(img).convert("L"))


def normalize(gray: np.ndarray) -> np.ndarray:
    """Растяжение контраста к диапазону 0..255."""
    g = gray.astype(np.float32)
    lo, hi = float(g.min()), float(g.max())
    if hi - lo < 1e-6:
        return gray.astype(np.uint8)
    out = (g - lo) / (hi - lo) * 255.0
    return out.astype(np.uint8)


def prepare(img: np.ndarray) -> np.ndarray:
    """Полный препроцессинг для OCR."""
    return normalize(to_grayscale(img))
```

- [ ] **Step 4: Запустить — проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_preprocess.py -v`
Expected: PASS (2 passed).

- [ ] **Step 5: Реализовать адаптер (импорт PaddleOCR — ленивый)**

```python
# src/ocr_service/ocr/__init__.py
"""OCR-адаптеры (PaddleOCR) и препроцессинг."""
```

```python
# src/ocr_service/ocr/paddle_adapter.py
"""Адаптер PaddleOCR: фото-байты → Observation[] (нормализованная геометрия)."""
from __future__ import annotations

import io

import numpy as np
from PIL import Image

from ocr_service.models import Observation
from ocr_service.ocr.preprocess import prepare


class PaddleAdapter:
    """Ленивая обёртка над PaddleOCR (импорт внутри, чтобы не тянуть в тестах ядра)."""

    def __init__(self) -> None:
        from paddleocr import PaddleOCR  # heavy, only in Docker

        self._ocr = PaddleOCR(lang="cyrillic", use_angle_cls=True, show_log=False)

    def recognize(self, photo_bytes: bytes) -> list[Observation]:
        img = np.asarray(Image.open(io.BytesIO(photo_bytes)).convert("RGB"))
        prepped = prepare(img)
        result = self._ocr.ocr(prepped, cls=True)
        return _to_observations(result)


def _to_observations(paddle_result) -> list[Observation]:
    """Преобразует выход PaddleOCR в Observation (bbox=x,y,w,h, origin top-left)."""
    out: list[Observation] = []
    for page in paddle_result or []:
        for line in page or []:
            poly, (text, conf) = line
            xs = [p[0] for p in poly]
            ys = [p[1] for p in poly]
            x, y = min(xs), min(ys)
            out.append(
                Observation(
                    text=text,
                    bbox=(x, y, max(xs) - x, max(ys) - y),
                    confidence=float(conf),
                )
            )
    return out
```

- [ ] **Step 6: Тест контракта адаптера через мок**

```python
# дополнить tests/test_preprocess.py
from ocr_service.ocr.paddle_adapter import _to_observations


def test_to_observations_maps_polygon_to_bbox():
    fake = [[
        [[[40, 150], [420, 150], [420, 168], [40, 168]], ("Молоко", 0.95)],
    ]]
    obs = _to_observations(fake)
    assert len(obs) == 1
    assert obs[0].text == "Молоко"
    assert obs[0].bbox == (40, 150, 380, 18)
    assert obs[0].confidence == 0.95
```

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_preprocess.py -v`
Expected: PASS (3 passed).

- [ ] **Step 7: Commit**

```bash
git add ocr-service/src/ocr_service/ocr/ ocr-service/tests/test_preprocess.py
git commit -m "feat(ocr): preprocessing and PaddleOCR adapter contract"
```

---

### Task 11: FastAPI-эндпоинт POST /ocr

**Files:**
- Create: `ocr-service/src/ocr_service/api/__init__.py` (пустой)
- Create: `ocr-service/src/ocr_service/api/main.py`
- Test: `ocr-service/tests/test_api.py`

Эндпоинт принимает байты фото, прогоняет адаптер → парсер, отдаёт JSON по контракту.
Адаптер инъектируется (в тесте — фейковый, без PaddleOCR).

- [ ] **Step 1: Тест API с фейковым адаптером**

```python
# tests/test_api.py
from fastapi.testclient import TestClient

from ocr_service.api.main import create_app
from tests.fixtures.prostore import PROSTORE


class FakeAdapter:
    def recognize(self, photo_bytes: bytes):
        return PROSTORE


def test_ocr_endpoint_returns_items():
    app = create_app(adapter=FakeAdapter())
    client = TestClient(app)
    resp = client.post("/ocr", files={"photo": ("r.jpg", b"x", "image/jpeg")})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 4
    assert data["total"] == 28.72
    assert data["confidence"] >= 0.9
    assert {"raw_name", "qty", "unit_price", "sum", "confidence"} <= set(data["items"][0])
```

- [ ] **Step 2: Запустить — падает**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_api.py -v`
Expected: FAIL — `create_app` не найден.

- [ ] **Step 3: Реализовать API**

```python
# src/ocr_service/api/main.py
"""FastAPI-сервис: POST /ocr (фото → распознанные позиции)."""
from __future__ import annotations

from dataclasses import asdict

from fastapi import FastAPI, File, UploadFile

from ocr_service.parser import parse


def create_app(adapter=None) -> FastAPI:
    """Создаёт приложение. adapter инъектируется (в тестах — фейковый)."""
    app = FastAPI(title="ChekiPrices OCR")

    def get_adapter():
        nonlocal adapter
        if adapter is None:
            from ocr_service.ocr.paddle_adapter import PaddleAdapter

            adapter = PaddleAdapter()
        return adapter

    @app.get("/health")
    def health():
        return {"status": "ok"}

    @app.post("/ocr")
    async def ocr(photo: UploadFile = File(...)):
        data = await photo.read()
        observations = get_adapter().recognize(data)
        receipt = parse(observations)
        return {
            "items": [asdict(i) for i in receipt.items],
            "total": receipt.total,
            "confidence": receipt.confidence,
        }

    return app


app = create_app()  # для uvicorn ocr_service.api.main:app
```

Создать пустой `src/ocr_service/api/__init__.py`.

- [ ] **Step 4: Запустить — проходит**

Run: `cd ocr-service && . .venv/bin/activate && pytest tests/test_api.py -v`
Expected: PASS (1 passed).

- [ ] **Step 5: Прогнать все локальные тесты**

Run: `cd ocr-service && . .venv/bin/activate && pytest -q`
Expected: все PASS (модели, парсер, препроцессинг, API).

- [ ] **Step 6: Commit**

```bash
git add ocr-service/src/ocr_service/api/ ocr-service/tests/test_api.py
git commit -m "feat(ocr): FastAPI POST /ocr endpoint"
```

---

### Task 12: Dockerfile + README + CI-job

**Files:**
- Create: `ocr-service/Dockerfile`
- Create: `ocr-service/README.md`
- Modify: `.github/workflows/ci.yml` (добавить job `ocr-service`)

> Docker локально недоступен — образ собирается/проверяется в CI. Локально проверяем
> только pytest (уже зелёный).

- [ ] **Step 1: Dockerfile**

```dockerfile
# ocr-service/Dockerfile
FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt requirements-ocr.txt ./
RUN pip install --no-cache-dir -r requirements.txt -r requirements-ocr.txt

COPY pyproject.toml ./
COPY src ./src
RUN pip install --no-cache-dir -e .

EXPOSE 8000
CMD ["uvicorn", "ocr_service.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

- [ ] **Step 2: README**

```markdown
# ocr-service

Python OCR-сервис ChekiPrices: фото чека → распознанные позиции (PaddleOCR + магазин-агностичный парсер).

## Контракт
`POST /ocr` (multipart `photo`, JPEG) →
`{ items: [{raw_name, qty, unit_price, sum, confidence, barcode?}], total?, confidence }`

## Локально (без PaddleOCR — тесты ядра)
    python3 -m venv .venv && . .venv/bin/activate
    pip install -r requirements-dev.txt && pip install -e .
    pytest -q

## Docker (с PaddleOCR)
    docker build -t cheki-ocr .
    docker run -p 8000:8000 cheki-ocr
```

- [ ] **Step 3: Добавить CI-job**

В `.github/workflows/ci.yml` добавить job (после существующих):

```yaml
  ocr-service:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ocr-service
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements-dev.txt && pip install -e .
      - run: pytest -q
      - run: docker build -t cheki-ocr .
```

- [ ] **Step 4: Проверить синтаксис workflow**

Run: `cd /Users/pablo/work/receipt-scan-app && python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); print('ok')"`
Expected: `ok`.

- [ ] **Step 5: Commit**

```bash
git add ocr-service/Dockerfile ocr-service/README.md .github/workflows/ci.yml
git commit -m "ci(ocr): dockerfile, readme and ci job for ocr-service"
```

---

## Self-Review (выполнено при написании плана)

- **Spec coverage:** Компонент 1 (парсер) — Tasks 1–9; Компонент 2 (OCR-сервис:
  PaddleOCR-адаптер, FastAPI) — Tasks 10–12. Магазин-агностичность (геометрия/
  арифметика/классы лексем/самоопределяемые границы/сверка) — Tasks 3–9. Confidence и
  сверка — Tasks 8–9. Компоненты 3 (PHP-воркер), 4 (клиент) и миграция БД — отдельные
  планы (вне этого).
- **Placeholders:** нет — каждый шаг с кодом и командой.
- **Type consistency:** `Observation(text,bbox,confidence)`, `ParsedItem(raw_name,qty,
  unit_price,sum,confidence,barcode)`, `ParsedReceipt(items,total,confidence)` —
  единообразны во всех тестах и реализациях; `parse()`, `group_rows()`,
  `money_column_x()`, `split_region()`, `infer_price_qty_sum()`,
  `extract_name_and_barcode()`, `is_name_continuation()`, `name_text_of_row()`,
  `item_confidence()`, `receipt_confidence()` — имена совпадают между задачами.

## Известные риски (для исполнителя)

- Пороги геометрии (60px для x-кластера, 80px для близости к денежной колонке, 40px для
  «слева от колонки») подобраны под фикстуру. На реальных чеках их, возможно, придётся
  сделать относительными (доля ширины изображения), а не абсолютными — это допустимое
  универсальное улучшение, НЕ правило под магазин.
- `infer_price_qty_sum` для строк с >2 чисел использует перебор перестановок — на
  реальном шуме может ошибаться; при провале сверки чек уходит на ревью (by design).
