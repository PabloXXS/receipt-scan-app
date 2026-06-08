#!/usr/bin/env bash
# PostToolUse(Edit|Write): автоформатирование отредактированного Dart-файла.
# Вход: JSON на stdin (.tool_input.file_path). Не блокирует — всегда exit 0.
set -euo pipefail

input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$f" ] || exit 0

case "$f" in
  *.dart)
    if command -v dart >/dev/null 2>&1 && [ -f "$f" ]; then
      dart format "$f" >/dev/null 2>&1 || true
    fi
    ;;
esac
exit 0
