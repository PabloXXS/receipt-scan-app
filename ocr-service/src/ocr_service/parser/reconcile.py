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
