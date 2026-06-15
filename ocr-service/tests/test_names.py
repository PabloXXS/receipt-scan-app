from ocr_service.parser.names import extract_name_and_barcode


def test_strips_leading_barcode():
    name, code = extract_name_and_barcode("5449000131843 Напиток Coca-Cola без сахара")
    assert code == "5449000131843"
    assert name == "Напиток Coca-Cola без сахара"


def test_no_barcode():
    name, code = extract_name_and_barcode("Хлеб Бородинский")
    assert code is None
    assert name == "Хлеб Бородинский"


def test_short_number_is_not_barcode():
    name, code = extract_name_and_barcode("2 шт Молоко")
    assert code is None
    assert name == "2 шт Молоко"
