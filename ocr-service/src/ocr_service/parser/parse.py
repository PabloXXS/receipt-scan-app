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
        # имя: строки-продолжения выше денежной строки + текст самой строки.
        # В чеках название предшествует цене; идём вверх до предыдущей позиции или
        # до строки, не являющейся продолжением названия (заголовок/шапка).
        name_parts = [name_text_of_row(r, col)]
        ri = idx_of[id(r)]
        j = ri - 1
        while j >= 0 and rows[j] not in item_rows and is_name_continuation(rows[j], col):
            name_parts.insert(0, name_text_of_row(rows[j], col))
            j -= 1
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
