# Dockerfile для Tesseract OCR API сервиса
FROM node:20-alpine

# Установка Tesseract и зависимостей
RUN apk add --no-cache \
    tesseract-ocr \
    tesseract-ocr-data-rus \
    tesseract-ocr-data-eng \
    imagemagick \
    graphicsmagick

# Создание рабочей директории
WORKDIR /app

# Копирование package файлов
COPY package*.json ./

# Установка зависимостей
RUN npm ci --only=production

# Копирование исходного кода
COPY . .

# Экспозиция порта
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

# Запуск сервера
CMD ["node", "server.js"]

