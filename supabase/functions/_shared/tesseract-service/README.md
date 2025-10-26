# Tesseract OCR API Service

HTTP API для распознавания текста с изображений чеков с использованием Tesseract OCR.

## Возможности

- OCR распознавание с поддержкой русского и английского языков
- Автоматическая предобработка изображений (grayscale, threshold, sharpen)
- Настраиваемые параметры Tesseract (PSM, language)
- Health check endpoint
- Docker контейнеризация

## Быстрый старт

### Локальная разработка с Docker Compose

```bash
# Сборка и запуск
docker-compose up --build

# Проверка здоровья сервиса
curl http://localhost:3000/health

# Тестовый запрос OCR
curl -X POST http://localhost:3000/ocr \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://example.com/receipt.jpg",
    "language": "rus+eng",
    "psm": 6,
    "preprocess": true
  }'
```

### Локальная разработка без Docker

```bash
# Установка зависимостей системы (macOS)
brew install tesseract tesseract-lang imagemagick

# Установка Node.js зависимостей
npm install

# Запуск сервера
npm start

# Разработка с hot reload
npm run dev
```

## API Documentation

### POST /ocr

Выполняет OCR распознавание изображения.

**Request Body:**

```json
{
  "image_url": "string (required)",
  "language": "string (optional, default: 'rus+eng')",
  "psm": "number (optional, default: 6)",
  "preprocess": "boolean (optional, default: true)"
}
```

**Response:**

```json
{
  "text": "string",
  "confidence": "number (0-100)",
  "processing_time_ms": "number",
  "lines_count": "number"
}
```

**PSM Modes (Page Segmentation Mode):**

- `0` - Orientation and script detection (OSD) only
- `3` - Fully automatic page segmentation, but no OSD
- `6` - Uniform block of text (рекомендуется для чеков)
- `11` - Sparse text
- `13` - Raw line

### GET /health

Health check endpoint.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.45,
  "service": "tesseract-ocr-api"
}
```

## Deployment

### Railway

```bash
# Установка Railway CLI
npm install -g railway

# Логин
railway login

# Инициализация проекта
railway init

# Деплой
railway up
```

### Fly.io

```bash
# Установка flyctl
curl -L https://fly.io/install.sh | sh

# Логин
flyctl auth login

# Инициализация
flyctl launch

# Деплой
flyctl deploy
```

### DigitalOcean App Platform

1. Создать новый App
2. Выбрать Docker source
3. Указать порт 3000
4. Deploy

## Environment Variables

- `PORT` - Порт сервера (default: 3000)
- `NODE_ENV` - Окружение (development/production)

## Производительность

- Среднее время обработки: 1-3 секунды на чек
- Memory usage: ~150-200 MB
- CPU: зависит от размера изображения

## Troubleshooting

### Tesseract не найден

```bash
# Ubuntu/Debian
apt-get install tesseract-ocr tesseract-ocr-rus tesseract-ocr-eng

# macOS
brew install tesseract tesseract-lang

# Alpine (Docker)
apk add tesseract-ocr tesseract-ocr-data-rus tesseract-ocr-data-eng
```

### Низкое качество распознавания

1. Включить `preprocess: true`
2. Попробовать разные PSM режимы (6, 11, 13)
3. Убедиться, что изображение хорошего качества (минимум 300 DPI)

## License

MIT
