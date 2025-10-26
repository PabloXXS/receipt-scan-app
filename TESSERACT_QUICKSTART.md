# Tesseract OCR - Quick Start Guide

> **💡 Важно:** Tesseract OCR — это **полностью бесплатное** open-source решение (Apache 2.0).
> Единственная стоимость — это хостинг Docker контейнера (~$0-5/мес на Fly.io).
> При нагрузке до 15,000 чеков/месяц — **полностью бесплатно** на Fly.io!

## Что было сделано

✅ Создан микросервис Tesseract OCR с HTTP API  
✅ Docker контейнеризация с автоматической предобработкой изображений  
✅ Интеграция с Supabase Edge Functions (analyze)  
✅ Fallback механизм между разными OCR провайдерами  
✅ Документация по деплою на Fly.io, Railway, DigitalOcean

## Архитектура

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │ Upload image
         ↓
┌─────────────────┐
│ Supabase Storage│
└────────┬────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│     Supabase Edge Function (analyze)    │
│                                          │
│  ┌──────────┐  ┌──────────┐  ┌────────┐│
│  │Tesseract │  │  OpenAI  │  │OCR.space││
│  │   OCR    │  │  Vision  │  │         ││
│  └──────────┘  └──────────┘  └────────┘│
│         │              │           │     │
│         └──────────────┴───────────┘     │
│                   ↓                      │
│           Text Parser & Mapper           │
└─────────────────┬───────────────────────┘
                  ↓
         ┌────────────────┐
         │ PostgreSQL DB  │
         └────────────────┘
```

## Локальный запуск (для тестирования)

### 1. Запуск Tesseract сервиса

```bash
cd supabase/functions/_shared/tesseract-service

# Сборка и запуск
docker-compose up --build

# Проверка здоровья
curl http://localhost:3000/health

# Тест OCR
./test-request.sh
```

### 2. Настройка локального Supabase

```bash
# В корне проекта
cd /Users/pablo/work/receipt-scan-app

# Запуск Supabase локально (если еще не запущен)
supabase start

# Установить переменную для локального Tesseract
supabase secrets set --env-file .env.local TESSERACT_OCR_URL=http://host.docker.internal:3000

# Или для тестирования - установить AI_PROVIDER
supabase secrets set --env-file .env.local AI_PROVIDER=tesseract
```

### 3. Тестирование через Flutter

```bash
# Запуск Flutter приложения
flutter run -d chrome

# Загрузить тестовый чек из assets/
# Система автоматически вызовет analyze function
# который использует Tesseract (если AI_PROVIDER=tesseract)
```

## Деплой в продакшн

### Вариант 1: Fly.io (рекомендуется, БЕСПЛАТНО)

```bash
# 1. Установка flyctl
curl -L https://fly.io/install.sh | sh

# 2. Логин
flyctl auth login

# 3. Деплой Tesseract сервиса
cd supabase/functions/_shared/tesseract-service
flyctl launch --name tesseract-ocr-receipt

# При запросе выбрать:
# - Region: ams (Amsterdam) или ближайший
# - Postgres: No
# - Redis: No

# 4. Деплой
flyctl deploy

# 5. Получить URL
flyctl info
# Пример: https://tesseract-ocr-receipt.fly.dev
```

### Вариант 2: Railway (простой деплой)

```bash
# 1. Установка Railway CLI
npm install -g railway

# 2. Логин
railway login

# 3. Деплой
cd supabase/functions/_shared/tesseract-service
railway init
railway up

# 4. Получить URL
railway domain
```

### Настройка Supabase после деплоя

```bash
# Установить URL задеплоенного Tesseract сервиса
supabase secrets set TESSERACT_OCR_URL=https://tesseract-ocr-receipt.fly.dev

# Опционально: сделать Tesseract основным провайдером
supabase secrets set AI_PROVIDER=tesseract

# Или оставить OpenAI с fallback на Tesseract (рекомендуется)
supabase secrets set AI_PROVIDER=openai
```

### Деплой Edge Functions

```bash
# Деплой analyze function с новой интеграцией
supabase functions deploy analyze

# Проверка
supabase functions logs analyze
```

## Переменные окружения

### Tesseract Service

- `PORT` - порт сервера (default: 3000)
- `NODE_ENV` - окружение (development/production)

### Supabase Edge Functions

- `TESSERACT_OCR_URL` - URL задеплоенного Tesseract сервиса
- `AI_PROVIDER` - основной провайдер: `tesseract`, `openai`, или `ocrspace`
- `OPENAI_API_KEY` - для fallback на OpenAI Vision
- `OCR_SPACE_API_KEY` - для fallback на OCR.space

## Режимы работы

### 1. Tesseract Primary (экономия средств)

```bash
supabase secrets set AI_PROVIDER=tesseract
```

- Tesseract → fallback на OpenAI при неудаче
- **Стоимость:**
  - Tesseract OCR: **бесплатно** (open-source)
  - Хостинг сервиса: ~$0-5/месяц на Fly.io
  - При 500-5000 чеков/месяц → **~$0-0.001 за чек**

### 2. OpenAI Primary (лучшее качество, default)

```bash
supabase secrets set AI_PROVIDER=openai
```

- OpenAI Vision → fallback на Tesseract → fallback на OCR.space
- Стоимость: ~$0.01-0.02 за чек

### 3. OCR.space Primary

```bash
supabase secrets set AI_PROVIDER=ocrspace
```

- OCR.space → fallback на OpenAI
- Стоимость: бесплатно до 25k запросов/месяц

## Тестирование

### Проверка здоровья Tesseract

```bash
curl https://tesseract-ocr-receipt.fly.dev/health
```

### Тест OCR через API

```bash
curl -X POST https://tesseract-ocr-receipt.fly.dev/ocr \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://example.com/receipt.jpg",
    "language": "rus+eng",
    "psm": 6,
    "preprocess": true
  }'
```

### Тест через Edge Function

```bash
# Через Supabase CLI
supabase functions invoke analyze \
  --env-file .env.local \
  --body '{"url":"https://example.com/receipt.jpg"}'
```

## Мониторинг

### Логи Tesseract (Fly.io)

```bash
flyctl logs
```

### Логи Edge Function

```bash
supabase functions logs analyze --tail
```

### Метрики

Tesseract логирует:

- Время обработки (processing_time_ms)
- Уверенность распознавания (confidence 0-100)
- Количество строк (lines_count)
- Ошибки и fallback'и

## Troubleshooting

### Проблема: Tesseract сервис не отвечает

```bash
# Проверить статус
flyctl status

# Перезапустить
flyctl apps restart tesseract-ocr-receipt

# Проверить логи
flyctl logs
```

### Проблема: Низкое качество распознавания

1. Включить предобработку: `preprocess: true` в запросе
2. Попробовать другой PSM mode (6, 11, или 13)
3. Проверить качество исходного изображения

### Проблема: Медленная обработка

1. Увеличить ресурсы Fly.io: `flyctl scale vm shared-cpu-2x`
2. Отключить предобработку: `preprocess: false`
3. Использовать OpenAI Vision как primary

## Стоимость

### Tesseract на Fly.io

**Tesseract OCR сам по себе бесплатный (open-source).** Стоимость относится только к хостингу:

- **Бесплатный план:** 3 shared-cpu-1x (256MB) до $5/месяц кредитов
- **Реальная нагрузка:**
  - 100-500 чеков/день (3,000-15,000/мес) → **полностью бесплатно** на Fly.io
  - 15,000+ чеков/месяц → ~$2-5/мес → **$0.0001-0.0003 за чек**
- **Scale to zero:** если нет запросов → не платите ничего

### Сравнение провайдеров

| Провайдер     | Стоимость софта             | Стоимость хостинга/API | Итого за чек   | Скорость | Качество |
| ------------- | --------------------------- | ---------------------- | -------------- | -------- | -------- |
| Tesseract     | **Бесплатно** (open-source) | ~$0-5/мес (Fly.io)     | **~$0-0.001**  | 1-3 сек  | ★★★☆☆    |
| OpenAI Vision | -                           | Pay per use            | **$0.01-0.02** | 1-2 сек  | ★★★★★    |
| OCR.space     | -                           | Бесплатно до 25k/мес   | **$0**         | 2-4 сек  | ★★★☆☆    |

## Рекомендуемая конфигурация

### Для MVP/тестирования:

```bash
AI_PROVIDER=tesseract
TESSERACT_OCR_URL=https://tesseract-ocr-receipt.fly.dev
```

### Для продакшна:

```bash
AI_PROVIDER=openai
TESSERACT_OCR_URL=https://tesseract-ocr-receipt.fly.dev
OPENAI_API_KEY=sk-xxx
```

- OpenAI дает лучшее качество
- Tesseract как бесплатный fallback
- Optimal balance: качество + надежность

## Дальнейшие улучшения

- [ ] Кэширование результатов OCR для идентичных изображений
- [ ] Батчинг: обработка нескольких чеков одновременно
- [ ] Автоматический выбор провайдера на основе качества изображения
- [ ] A/B тестирование разных провайдеров
- [ ] Метрики и дашборд для анализа качества

## Полезные ссылки

- [Tesseract Deployment Guide](./docs/tesseract_deployment.md)
- [AI Pipeline Documentation](./docs/ai_pipeline.md)
- [Fly.io Documentation](https://fly.io/docs/)
- [Railway Documentation](https://docs.railway.app/)

---

💡 **Tip:** Начните с Fly.io деплоя Tesseract + OpenAI primary. Это даст лучшее качество с надежным fallback'ом.

🚀 **Ready to deploy?** Follow the commands above and you'll have Tesseract OCR running in 5 minutes!
