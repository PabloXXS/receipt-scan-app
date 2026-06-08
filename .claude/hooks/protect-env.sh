#!/usr/bin/env bash
# PreToolUse(Edit|Write): запрет правок .env-файлов с секретами.
# .env.example разрешён (это шаблон). Блокировка через exit 2 (stderr виден Claude).
set -euo pipefail

input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$f" ] || exit 0

case "$f" in
  *.env.example)
    exit 0
    ;;
  *.env|*/.env|*.env.local|*.env.development|*.env.production)
    echo "Заблокировано: правка файла секретов ($f). Шаблоны храните в .env.example; реальные значения задавайте вне репозитория (окружение/секрет-менеджер)." >&2
    exit 2
    ;;
esac
exit 0
