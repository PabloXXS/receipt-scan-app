# Tesseract OCR Service - Deployment Guide

## Обзор

Tesseract OCR Service — это микросервис для распознавания текста с изображений чеков. Работает как HTTP API и интегрируется с Supabase Edge Functions.

## Локальная разработка

### Требования

- Docker & Docker Compose
- ИЛИ Node.js 18+ и Tesseract OCR

### Запуск с Docker Compose

```bash
cd supabase/functions/_shared/tesseract-service

# Сборка и запуск
docker-compose up --build

# Проверка здоровья
curl http://localhost:3000/health

# Тест OCR
chmod +x test-request.sh
./test-request.sh
```

### Запуск без Docker (macOS)

```bash
# Установка Tesseract
brew install tesseract tesseract-lang imagemagick

# Установка зависимостей
npm install

# Запуск
npm start

# Для разработки с hot reload
npm run dev
```

## Деплой в продакшн

### Вариант 1: Fly.io (рекомендуется)

**Преимущества:**

- Бесплатный план (ресурсов хватает)
- Автомасштабирование (scale to zero)
- Глобальное распределение

**Инструкция:**

```bash
# Установка flyctl
curl -L https://fly.io/install.sh | sh

# Логин
flyctl auth login

# Переход в директорию сервиса
cd supabase/functions/_shared/tesseract-service

# Запуск (создаст приложение и задеплоит)
flyctl launch

# Или деплой вручную
flyctl apps create tesseract-ocr-service
flyctl deploy

# Получить URL
flyctl info
# Output: https://tesseract-ocr-service.fly.dev
```

**Настройка в Supabase:**

```bash
# Установить переменную окружения в Supabase
supabase secrets set TESSERACT_OCR_URL=https://tesseract-ocr-service.fly.dev

# Установить AI_PROVIDER
supabase secrets set AI_PROVIDER=tesseract
```

### Вариант 2: Railway

**Преимущества:**

- Простой деплой из GitHub
- $5 бесплатных кредитов в месяц

**Инструкция:**

```bash
# Установка Railway CLI
npm install -g railway

# Логин
railway login

# Переход в директорию сервиса
cd supabase/functions/_shared/tesseract-service

# Инициализация
railway init

# Деплой
railway up

# Получить URL
railway domain
```

**Настройка переменных в Railway:**

- `PORT`: 3000
- `NODE_ENV`: production

### Вариант 3: DigitalOcean App Platform

**Преимущества:**

- $200 кредитов для новых пользователей
- Надежная инфраструктура

**Инструкция:**

1. Зайти на [DigitalOcean App Platform](https://cloud.digitalocean.com/apps)
2. Нажать "Create App"
3. Выбрать источник: GitHub/GitLab или Docker Hub
4. Указать репозиторий и путь к Dockerfile
5. Настроить:
   - **Docker Context:** `supabase/functions/_shared/tesseract-service`
   - **Dockerfile Path:** `Dockerfile`
   - **HTTP Port:** 3000
   - **Health Check:** `/health`
6. Deploy

### Вариант 4: Self-hosted VPS

**Требования:**

- Ubuntu 20.04+ или аналог
- Docker установлен

```bash
# На сервере
git clone <your-repo>
cd receipt-scan-app/supabase/functions/_shared/tesseract-service

# Сборка
docker build -t tesseract-ocr .

# Запуск
docker run -d \
  --name tesseract-ocr \
  --restart unless-stopped \
  -p 3000:3000 \
  tesseract-ocr

# Проверка
curl http://localhost:3000/health
```

**Настройка Nginx reverse proxy:**

```nginx
server {
    listen 80;
    server_name tesseract.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Настройка в Supabase Edge Functions

После деплоя сервиса, настроить переменные в Supabase:

```bash
# URL задеплоенного Tesseract сервиса
supabase secrets set TESSERACT_OCR_URL=https://your-service-url.com

# Установить Tesseract как основной провайдер (опционально)
supabase secrets set AI_PROVIDER=tesseract

# Или использовать OpenAI с fallback на Tesseract
supabase secrets set AI_PROVIDER=openai
```

## Мониторинг

### Health Check

```bash
curl https://your-service-url.com/health
```

Ожидаемый ответ:

```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.45,
  "service": "tesseract-ocr-api"
}
```

### Логи

**Fly.io:**

```bash
flyctl logs
```

**Railway:**

```bash
railway logs
```

**Docker:**

```bash
docker logs tesseract-ocr
```

## Масштабирование

### Fly.io

```bash
# Увеличить ресурсы
flyctl scale vm shared-cpu-2x --memory 1024

# Увеличить количество инстансов
flyctl scale count 2

# Настроить автомасштабирование
flyctl autoscale set min=1 max=5
```

### Railway

В веб-интерфейсе Railway:

- Settings → Resources → Adjust CPU/Memory

## Troubleshooting

### Ошибка: "TESSERACT_OCR_URL is not set"

```bash
# Проверить переменные в Supabase
supabase secrets list

# Установить переменную
supabase secrets set TESSERACT_OCR_URL=https://your-url.com
```

### Медленная обработка

1. Увеличить ресурсы контейнера (CPU/Memory)
2. Отключить предобработку изображений: `preprocess: false`
3. Использовать более быстрый PSM режим

### Низкое качество распознавания

1. Включить предобработку: `preprocess: true`
2. Попробовать разные PSM режимы (6, 11, 13)
3. Убедиться, что изображение хорошего качества

## Стоимость

### Fly.io

- **Бесплатный план:** 3 shared-cpu-1x (256MB RAM) - достаточно для MVP
- **Платный план:** ~$2-5/месяц за 1 инстанс

### Railway

- **Бесплатно:** $5 кредитов/месяц
- **Платный план:** Pay-as-you-go, ~$5-10/месяц

### DigitalOcean

- **Basic Plan:** $5/месяц (512MB RAM, 1 vCPU)

### Self-hosted VPS

- **DigitalOcean Droplet:** $6/месяц (1GB RAM, 1 vCPU)
- **Hetzner Cloud:** €4.15/месяц (2GB RAM, 1 vCPU)

## Безопасность

1. **Не экспонировать публично без аутентификации**

   - Использовать VPN или приватную сеть
   - Добавить API key аутентификацию

2. **Ограничения запросов**

   - Настроить rate limiting в Nginx/Caddy
   - Использовать Cloudflare для защиты

3. **HTTPS обязателен**
   - Все деплой платформы предоставляют бесплатный SSL

## Производительность

**Типичные метрики:**

- Время обработки: 1-3 секунды на чек
- Memory usage: ~150-200 MB
- CPU usage: spike во время OCR, потом idle

**Оптимизация:**

- Использовать CDN для кэширования статики
- Настроить connection pooling
- Включить gzip compression

---

💡 **Рекомендация:** Начните с Fly.io для быстрого старта. Позже можно мигрировать на self-hosted для экономии.
