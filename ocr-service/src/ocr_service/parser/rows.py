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
