from ocr_service.models import Observation
from ocr_service.parser.rows import group_rows


def _o(text, x, y, w=40, h=18):
    return Observation(text=text, bbox=(x, y, w, h), confidence=0.9)


def test_groups_same_line_and_sorts_by_x():
    obs = [_o("B", 200, 100), _o("A", 40, 102), _o("C", 400, 99)]
    rows = group_rows(obs)
    assert len(rows) == 1
    assert [o.text for o in rows[0]] == ["A", "B", "C"]


def test_separates_distinct_lines_top_to_bottom():
    obs = [_o("line2", 40, 140), _o("line1", 40, 100)]
    rows = group_rows(obs)
    assert [r[0].text for r in rows] == ["line1", "line2"]
