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
