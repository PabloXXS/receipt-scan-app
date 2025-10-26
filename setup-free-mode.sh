#!/bin/bash

# Скрипт автоматической настройки бесплатного режима
# Использование: ./setup-free-mode.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}╔═══════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Настройка бесплатного режима Ticket App  ║${NC}"
echo -e "${YELLOW}╚═══════════════════════════════════════════╝${NC}"
echo ""

# Проверка зависимостей
echo -e "${YELLOW}1. Проверка зависимостей...${NC}"

if ! command -v flyctl &> /dev/null; then
    echo -e "${RED}✗ Fly.io CLI не установлен${NC}"
    echo "Установите: curl -L https://fly.io/install.sh | sh"
    exit 1
fi
echo -e "${GREEN}✓ Fly.io CLI установлен${NC}"

if ! command -v supabase &> /dev/null; then
    echo -e "${RED}✗ Supabase CLI не установлен${NC}"
    echo "Установите: brew install supabase/tap/supabase"
    exit 1
fi
echo -e "${GREEN}✓ Supabase CLI установлен${NC}"

echo ""

# Проверка авторизации Fly.io
echo -e "${YELLOW}2. Проверка авторизации Fly.io...${NC}"
if ! flyctl auth whoami &> /dev/null; then
    echo -e "${YELLOW}Необходима авторизация в Fly.io${NC}"
    flyctl auth login
fi
echo -e "${GREEN}✓ Авторизован в Fly.io${NC}"
echo ""

# Деплой Tesseract
echo -e "${YELLOW}3. Деплой Tesseract OCR на Fly.io (бесплатно)...${NC}"
cd supabase/functions/_shared/tesseract-service

# Проверка существования приложения
if flyctl apps list | grep -q "tesseract-ocr-receipt"; then
    echo -e "${YELLOW}Приложение уже существует, обновляем...${NC}"
    flyctl deploy
else
    echo -e "${YELLOW}Создаем новое приложение...${NC}"
    flyctl launch --name tesseract-ocr-receipt \
        --region ams \
        --vm-size shared-cpu-1x \
        --vm-memory 256 \
        --no-deploy
    
    flyctl deploy
fi

# Получение URL
TESSERACT_URL=$(flyctl info --json | grep -o '"Hostname":"[^"]*"' | cut -d'"' -f4)
TESSERACT_URL="https://$TESSERACT_URL"

echo -e "${GREEN}✓ Tesseract задеплоен: $TESSERACT_URL${NC}"
echo ""

# Health check
echo -e "${YELLOW}4. Проверка работы Tesseract...${NC}"
sleep 5  # даем время на запуск
if curl -s "$TESSERACT_URL/health" | grep -q "healthy"; then
    echo -e "${GREEN}✓ Tesseract работает корректно${NC}"
else
    echo -e "${RED}✗ Tesseract не отвечает, проверьте логи: flyctl logs${NC}"
    exit 1
fi
echo ""

# Возврат в корень проекта
cd ../../../../

# Настройка Supabase
echo -e "${YELLOW}5. Настройка Supabase...${NC}"

# Проверка линка к проекту
if ! supabase status &> /dev/null; then
    echo -e "${RED}✗ Проект не связан с Supabase${NC}"
    echo "Выполните: supabase link"
    exit 1
fi

# Установка переменных
echo "Устанавливаем переменные окружения..."

supabase secrets set AI_PROVIDER=tesseract
echo -e "${GREEN}✓ AI_PROVIDER=tesseract${NC}"

supabase secrets set TESSERACT_OCR_URL="$TESSERACT_URL"
echo -e "${GREEN}✓ TESSERACT_OCR_URL=$TESSERACT_URL${NC}"

# Опционально: OCR.space ключ
echo ""
echo -e "${YELLOW}Хотите добавить бесплатный OCR.space как fallback? (y/n)${NC}"
read -r USE_OCRSPACE

if [[ "$USE_OCRSPACE" == "y" ]]; then
    echo "Получите бесплатный ключ на: https://ocr.space/ocrapi"
    echo "Введите API ключ OCR.space (или Enter для пропуска):"
    read -r OCR_KEY
    
    if [[ -n "$OCR_KEY" ]]; then
        supabase secrets set OCR_SPACE_API_KEY="$OCR_KEY"
        echo -e "${GREEN}✓ OCR_SPACE_API_KEY установлен${NC}"
    fi
fi

# Удаление OpenAI ключа
echo ""
echo -e "${YELLOW}Удалить OpenAI API ключ? (рекомендуется для бесплатного режима) (y/n)${NC}"
read -r REMOVE_OPENAI

if [[ "$REMOVE_OPENAI" == "y" ]]; then
    supabase secrets unset OPENAI_API_KEY 2>/dev/null || true
    echo -e "${GREEN}✓ OPENAI_API_KEY удален${NC}"
fi

echo ""

# Деплой Edge Functions
echo -e "${YELLOW}6. Деплой Edge Functions...${NC}"
supabase functions deploy analyze
echo -e "${GREEN}✓ Функция analyze задеплоена${NC}"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ Бесплатный режим настроен успешно!    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 Итоговая конфигурация:${NC}"
echo "  • AI Provider: Tesseract (бесплатно)"
echo "  • Tesseract URL: $TESSERACT_URL"
echo "  • Хостинг: Fly.io Free Tier"
echo "  • Стоимость: \$0/месяц"
echo ""
echo -e "${YELLOW}🧪 Тестирование:${NC}"
echo "  1. Загрузите тестовый чек через приложение"
echo "  2. Проверьте логи: supabase functions logs analyze --tail"
echo "  3. Должно быть: '[ANALYZE] Используем Tesseract как основной метод'"
echo ""
echo -e "${YELLOW}📊 Лимиты бесплатного режима:${NC}"
echo "  • Fly.io: ~15,000 чеков/месяц (бесплатно)"
echo "  • OCR.space: 25,000 запросов/месяц (если настроен)"
echo "  • Supabase: 500k функций/месяц"
echo ""
echo -e "${YELLOW}📖 Документация:${NC}"
echo "  См. FREE_MODE_SETUP.md для подробной информации"
echo ""
echo -e "${GREEN}✨ Готово! Приложение работает в полностью бесплатном режиме! ✨${NC}"

