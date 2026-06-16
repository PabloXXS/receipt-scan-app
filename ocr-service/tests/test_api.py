from fastapi.testclient import TestClient

from ocr_service.api.main import create_app
from tests.fixtures.prostore import PROSTORE


class FakeAdapter:
    def recognize(self, photo_bytes: bytes):
        return PROSTORE


def test_ocr_endpoint_returns_items():
    app = create_app(adapter=FakeAdapter())
    client = TestClient(app)
    resp = client.post("/ocr", files={"photo": ("r.jpg", b"x", "image/jpeg")})
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) == 4
    assert data["total"] == 28.72
    assert data["confidence"] >= 0.9
    assert {"raw_name", "qty", "unit_price", "sum", "confidence"} <= set(data["items"][0])
