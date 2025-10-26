#!/bin/bash

# Тестовый скрипт для проверки Tesseract OCR API

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_URL="${TESSERACT_URL:-http://localhost:3000}"

echo -e "${YELLOW}=== Tesseract OCR API Test ===${NC}\n"

# 1. Health check
echo -e "${YELLOW}1. Testing health endpoint...${NC}"
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${BASE_URL}/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Health check passed${NC}"
    echo "$RESPONSE_BODY" | jq .
else
    echo -e "${RED}✗ Health check failed (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

echo ""

# 2. OCR test с тестовым изображением
echo -e "${YELLOW}2. Testing OCR endpoint...${NC}"

# Используем тестовое изображение (публичный URL)
TEST_IMAGE_URL="${TEST_IMAGE_URL:-https://raw.githubusercontent.com/tesseract-ocr/docs/main/tesseract.png}"

echo "Image URL: $TEST_IMAGE_URL"
echo ""

OCR_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${BASE_URL}/ocr" \
    -H "Content-Type: application/json" \
    -d "{
        \"image_url\": \"$TEST_IMAGE_URL\",
        \"language\": \"rus+eng\",
        \"psm\": 6,
        \"preprocess\": true
    }")

HTTP_CODE=$(echo "$OCR_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$OCR_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ OCR request successful${NC}"
    echo ""
    echo "Response:"
    echo "$RESPONSE_BODY" | jq .
    echo ""
    
    # Показываем распознанный текст
    TEXT=$(echo "$RESPONSE_BODY" | jq -r '.text')
    echo -e "${YELLOW}Recognized text:${NC}"
    echo "$TEXT"
else
    echo -e "${RED}✗ OCR request failed (HTTP $HTTP_CODE)${NC}"
    echo "$RESPONSE_BODY"
    exit 1
fi

echo ""
echo -e "${GREEN}=== All tests passed! ===${NC}"

