"""Доменные модели OCR-сервиса: наблюдение OCR и распознанный чек."""
from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class Observation:
    """Одно текстовое наблюдение OCR с геометрией. bbox=(x,y,w,h), origin top-left."""

    text: str
    bbox: tuple[float, float, float, float]
    confidence: float

    @property
    def x(self) -> float:
        return self.bbox[0]

    @property
    def y(self) -> float:
        return self.bbox[1]

    @property
    def w(self) -> float:
        return self.bbox[2]

    @property
    def h(self) -> float:
        return self.bbox[3]

    @property
    def right(self) -> float:
        return self.bbox[0] + self.bbox[2]

    @property
    def cx(self) -> float:
        return self.bbox[0] + self.bbox[2] / 2

    @property
    def cy(self) -> float:
        return self.bbox[1] + self.bbox[3] / 2


@dataclass(frozen=True)
class ParsedItem:
    """Распознанная позиция чека."""

    raw_name: str
    qty: float
    unit_price: float
    sum: float
    confidence: float
    barcode: str | None = None


@dataclass(frozen=True)
class ParsedReceipt:
    """Результат разбора чека."""

    items: list[ParsedItem] = field(default_factory=list)
    total: float | None = None
    confidence: float = 0.0

    @property
    def items_sum(self) -> float:
        return round(sum(i.sum for i in self.items), 2)
