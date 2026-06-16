from ocr_service.parser.reconcile import item_confidence, receipt_confidence


def test_item_confidence_high_when_arithmetic_holds():
    assert item_confidence(ocr_conf=0.9, unit=5.49, qty=1.0, sum_=5.49) > 0.85


def test_item_confidence_drops_when_arithmetic_breaks():
    low = item_confidence(ocr_conf=0.9, unit=5.49, qty=1.0, sum_=9.99)
    assert low < 0.6


def test_receipt_confidence_bonus_on_total_match():
    matched = receipt_confidence(item_confs=[0.9, 0.9], items_sum=10.0, total=10.0)
    mismatched = receipt_confidence(item_confs=[0.9, 0.9], items_sum=10.0, total=12.0)
    assert matched > mismatched
    assert matched >= 0.9
