#!/bin/bash
# Скрипт для перезагрузки схемы PostgREST

SUPABASE_URL="https://wolzvpuqmjsicjudkblr.supabase.co"
SERVICE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndvbHp2cHVxbWpzaWNqdWRrYmxyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczNDM0NDg4MCwiZXhwIjoyMDQ5OTIwODgwfQ.FhE5TUcFLAuIZVOpNhZIR2MsXEe6CZXxKOHYBz4gB8k"

echo "Sending NOTIFY to reload PostgREST schema..."
curl -X POST "${SUPABASE_URL}/rest/v1/rpc/pgrst_reload_schema" \
  -H "apikey: ${SERVICE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_KEY}" \
  -H "Content-Type: application/json"

echo ""
echo "Schema reload requested!"
