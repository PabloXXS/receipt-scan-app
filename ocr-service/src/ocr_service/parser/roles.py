"""Инференс ролей цена/кол-во/сумма из чисел строки по арифметике a*b≈c."""
from __future__ import annotations

import re
from itertools import permutations

from ocr_service.models import Observation
from ocr_service.parser.columns import is_money

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
        if abs(a * b - s_val) <= tol and a * b != 0:
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
