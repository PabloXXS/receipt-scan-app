# 🆓 Бесплатный режим - Краткая справка

## Быстрая настройка (5 минут)

### Автоматическая настройка

```bash
./setup-free-mode.sh
```

### Ручная настройка

#### 1. Деплой Tesseract на Fly.io

```bash
cd supabase/functions/_shared/tesseract-service
flyctl launch --name tesseract-ocr-receipt
flyctl deploy
```

#### 2. Настройка Supabase

```bash
# Установить переменные
supabase secrets set AI_PROVIDER=tesseract
supabase secrets set TESSERACT_OCR_URL=https://tesseract-ocr-receipt.fly.dev

# Деплой функций
supabase functions deploy analyze
```

#### 3. Проверка

```bash
# Health check
curl https://tesseract-ocr-receipt.fly.dev/health

# Логи
supabase functions logs analyze --tail
```

---

## 💰 Стоимость

| Сервис    | Бесплатный лимит    | Стоимость    |
| --------- | ------------------- | ------------ |
| Fly.io    | ~15,000 чеков/мес   | **$0**       |
| OCR.space | 25,000 запросов/мес | **$0**       |
| Supabase  | 500k функций/мес    | **$0**       |
| **ИТОГО** |                     | **$0/месяц** |

vs OpenAI Vision: **$150-300/месяц** для 15,000 чеков

---

## 📊 Качество распознавания

| Условия         | Точность |
| --------------- | -------- |
| ✅ Хорошее фото | 90-95%   |
| ⚠️ Среднее фото | 80-85%   |
| ❌ Плохое фото  | 60-70%   |

**Рекомендации пользователям:**

- 📸 Хорошее освещение
- 📐 Прямой угол съемки
- 🔍 Чек в фокусе
- ✨ Разглаженный чек

---

## 🔧 Команды управления

### Fly.io

```bash
flyctl status              # Статус приложения
flyctl logs                # Логи
flyctl scale vm shared-cpu-2x  # Увеличить ресурсы
flyctl apps restart        # Перезапуск
```

### Supabase

```bash
supabase secrets list      # Список переменных
supabase functions logs analyze --tail  # Логи функции
supabase functions deploy analyze       # Деплой функции
```

---

## 🎯 Режимы работы

### Бесплатный режим (текущий)

```bash
AI_PROVIDER=tesseract
```

- Tesseract OCR (primary)
- OCR.space (fallback)
- Стоимость: $0

### Вернуться к OpenAI

```bash
supabase secrets set AI_PROVIDER=openai
supabase secrets set OPENAI_API_KEY=sk-xxx
supabase functions deploy analyze
```

---

## 🆘 Troubleshooting

### Tesseract не отвечает

```bash
flyctl logs
flyctl apps restart tesseract-ocr-receipt
```

### Низкое качество распознавания

1. Проверить качество фото
2. Включить предобработку (по умолчанию включена)
3. Добавить OCR.space fallback

### Превышены лимиты Fly.io

```bash
# Увеличить ресурсы (~$5/мес)
flyctl scale vm shared-cpu-2x --memory 512
```

---

## 📖 Документация

- **Полная инструкция:** `FREE_MODE_SETUP.md`
- **Tesseract деплой:** `docs/tesseract_deployment.md`
- **Архитектура:** `docs/ai_pipeline.md`

---

## ✅ Checklist

- [ ] Tesseract задеплоен на Fly.io
- [ ] `AI_PROVIDER=tesseract` установлен
- [ ] `TESSERACT_OCR_URL` установлен
- [ ] Функция `analyze` задеплоена
- [ ] Health check работает
- [ ] Тестовый чек распознается

---

💡 **Совет:** Если качество не устраивает — добавьте OCR.space ключ как fallback (бесплатно 25k/мес)
