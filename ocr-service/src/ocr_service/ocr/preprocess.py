"""Препроцессинг фото чека: grayscale + нормализация контраста.

TODO (будущее): дескью и бинаризация — пока не реализованы.
"""
from __future__ import annotations

import numpy as np
from PIL import Image


def to_grayscale(img: np.ndarray) -> np.ndarray:
    """RGB→серый (или возврат как есть для 2D)."""
    if img.ndim == 2:
        return img
    return np.asarray(Image.fromarray(img).convert("L"))


def normalize(gray: np.ndarray) -> np.ndarray:
    """Растяжение контраста к диапазону 0..255."""
    g = gray.astype(np.float32)
    lo, hi = float(g.min()), float(g.max())
    if hi - lo < 1e-6:
        return gray.astype(np.uint8)
    out = (g - lo) / (hi - lo) * 255.0
    return out.astype(np.uint8)


def prepare(img: np.ndarray) -> np.ndarray:
    """Препроцессинг для OCR: grayscale + нормализация контраста."""
    return normalize(to_grayscale(img))
