"""FastAPI-сервис: POST /ocr (фото → распознанные позиции)."""
from __future__ import annotations

from dataclasses import asdict

from fastapi import FastAPI, File, UploadFile

from ocr_service.parser import parse


def create_app(adapter=None) -> FastAPI:
    """Создаёт приложение. adapter инъектируется (в тестах — фейковый)."""
    app = FastAPI(title="ChekiPrices OCR")

    def get_adapter():
        nonlocal adapter
        if adapter is None:
            from ocr_service.ocr.paddle_adapter import PaddleAdapter

            adapter = PaddleAdapter()
        return adapter

    @app.get("/health")
    def health():
        return {"status": "ok"}

    @app.post("/ocr")
    async def ocr(photo: UploadFile = File(...)):
        data = await photo.read()
        observations = get_adapter().recognize(data)
        receipt = parse(observations)
        return {
            "items": [asdict(i) for i in receipt.items],
            "total": receipt.total,
            "confidence": receipt.confidence,
        }

    return app


app = create_app()  # для uvicorn ocr_service.api.main:app
