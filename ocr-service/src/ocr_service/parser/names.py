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
