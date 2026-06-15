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
