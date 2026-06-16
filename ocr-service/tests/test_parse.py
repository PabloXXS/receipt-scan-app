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
