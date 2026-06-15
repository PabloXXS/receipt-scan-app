from ocr_service.parser.rows import group_rows
from ocr_service.parser.columns import money_column_x
from ocr_service.parser.region import split_region
from tests.fixtures.prostore import PROSTORE


def test_splits_items_and_footer_total():
    rows = group_rows(PROSTORE)
    col = money_column_x(PROSTORE)
    item_rows, total = split_region(rows, col)
    # 4 позиции: каждая начинается строкой названия с суммой ниже
    # item_rows — строки с денежным токеном в зоне позиций
    assert total == 28.72
    # последняя строка зоны позиций — не подвал (ИТОГО/Банк/Кассир исключены)
    texts = " ".join(o.text for r in item_rows for o in r)
    assert "Кассир" not in texts
    assert "Банк" not in texts
