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
