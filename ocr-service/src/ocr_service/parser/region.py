"""Границы зоны позиций и языконезависимый якорь итога."""
from __future__ import annotations

import re

from ocr_service.models import Observation
from ocr_service.parser.columns import is_money, money_value

_NUMBER = re.compile(r"\d+[.,]\d+|\d+")


def _numeric_token_count(row: list[Observation]) -> int:
    """Сколько токенов строки несут число (цена/кол-во/сумма)."""
    return sum(1 for o in row if _NUMBER.search(o.text.replace(",", ".")))


def _is_item_row(row: list[Observation], money_col_x: float | None) -> bool:
    """Строка-позиция: сумма в денежной колонке + ещё хотя бы один числовой токен
    (цена и/или кол-во), т.е. арифметическая тройка, а не одиночный итог-метка."""
    if _row_money(row, money_col_x) is None:
        return False
    return _numeric_token_count(row) >= 2


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
        if _is_item_row(row, money_col_x):
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
