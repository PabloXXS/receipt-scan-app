from ocr_service.models import Observation, ParsedItem, ParsedReceipt


def test_observation_right_edge_and_center():
    obs = Observation(text="5.49", bbox=(100, 200, 40, 12), confidence=0.9)
    assert obs.right == 140
    assert obs.cx == 120
    assert obs.cy == 206


def test_parsed_receipt_items_sum():
    r = ParsedReceipt(
        items=[
            ParsedItem(raw_name="A", qty=1, unit_price=2.0, sum=2.0, confidence=0.9),
            ParsedItem(raw_name="B", qty=2, unit_price=1.5, sum=3.0, confidence=0.8),
        ],
        total=5.0,
        confidence=0.85,
    )
    assert r.items_sum == 5.0
