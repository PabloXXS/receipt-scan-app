import numpy as np
from ocr_service.ocr.preprocess import to_grayscale, normalize
from ocr_service.ocr.paddle_adapter import _to_observations


def test_to_grayscale_reduces_channels():
    rgb = np.zeros((10, 10, 3), dtype=np.uint8)
    gray = to_grayscale(rgb)
    assert gray.ndim == 2


def test_normalize_returns_uint8():
    img = np.full((4, 4), 130, dtype=np.uint8)
    out = normalize(img)
    assert out.dtype == np.uint8
    assert out.shape == (4, 4)


def test_to_observations_maps_polygon_to_bbox():
    fake = [[
        [[[40, 150], [420, 150], [420, 168], [40, 168]], ("Молоко", 0.95)],
    ]]
    obs = _to_observations(fake)
    assert len(obs) == 1
    assert obs[0].text == "Молоко"
    assert obs[0].bbox == (40, 150, 380, 18)
    assert obs[0].confidence == 0.95
