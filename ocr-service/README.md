# ocr-service

Python OCR-сервис ChekiPrices: фото чека → распознанные позиции (PaddleOCR + магазин-агностичный парсер).

## Контракт
`POST /ocr` (multipart `photo`, JPEG) →
`{ items: [{raw_name, qty, unit_price, sum, confidence, barcode?}], total?, confidence }`

## Локально (без PaddleOCR — тесты ядра)
    python3 -m venv .venv && . .venv/bin/activate
    pip install -r requirements-dev.txt && pip install -e .
    pytest -q

## Docker (с PaddleOCR)
    docker build -t cheki-ocr .
    docker run -p 8000:8000 cheki-ocr
