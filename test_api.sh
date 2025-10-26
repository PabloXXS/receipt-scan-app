#!/bin/bash
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvbHp2cHVxbWpzaWNqdWRrYmxyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwNTg2NjAsImV4cCI6MjA3NDYzNDY2MH0.WAKxBMSVnwZknpR8Co7ckdU5nb1TEUPd-cdBcuJmqMk"
URL="https://wolzvpuqmjsicjudkblr.supabase.co"

echo "1. Проверяем доступные колонки в receipts:"
curl -s -X GET "${URL}/rest/v1/receipts?select=*&limit=1" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${ANON_KEY}" | jq '.'

echo ""
echo "2. Проверяем схему OpenAPI (какие поля видит PostgREST):"
curl -s -X GET "${URL}/rest/" \
  -H "apikey: ${ANON_KEY}" \
  -H "Accept: application/openapi+json" | jq '.definitions.receipts.properties | keys'
