"""Адаптер PaddleOCR: фото-байты → Observation[] (нормализованная геометрия)."""
from __future__ import annotations

import io

import numpy as np
from PIL import Image

from ocr_service.models import Observation
from ocr_service.ocr.preprocess import prepare


class PaddleAdapter:
    """Ленивая обёртка над PaddleOCR (импорт внутри, чтобы не тянуть в тестах ядра)."""

    def __init__(self) -> None:
        from paddleocr import PaddleOCR  # heavy, only in Docker

        self._ocr = PaddleOCR(lang="cyrillic", use_angle_cls=True, show_log=False)

    def recognize(self, photo_bytes: bytes) -> list[Observation]:
        img = np.asarray(Image.open(io.BytesIO(photo_bytes)).convert("RGB"))
        prepped = prepare(img)
        result = self._ocr.ocr(prepped, cls=True)
        return _to_observations(result)


def _to_observations(paddle_result) -> list[Observation]:
    """Преобразует выход PaddleOCR в Observation (bbox=x,y,w,h, origin top-left)."""
    out: list[Observation] = []
    for page in paddle_result or []:
        for line in page or []:
            poly, (text, conf) = line
            xs = [p[0] for p in poly]
            ys = [p[1] for p in poly]
            x, y = min(xs), min(ys)
            out.append(
                Observation(
                    text=text,
                    bbox=(x, y, max(xs) - x, max(ys) - y),
                    confidence=float(conf),
                )
            )
    return out
