#!/usr/bin/env bash
# PostToolUse(Edit|Write): необблокирующие напоминания.
#  1) Дизайн-система: хардкод цвета/стиля в lib/features/** → совет использовать токены темы.
#  2) Приватность: правка точки анонимизации (зона C) → напоминание про инвариант.
# Сигнал передаётся Claude через additionalContext (exit 0, не блокирует).
set -euo pipefail

input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$f" ] || exit 0

msg=""

case "$f" in
  */lib/features/*.dart)
    if [ -f "$f" ] && grep -nE 'Color\(0x|Colors\.[a-z]|TextStyle\(' "$f" >/dev/null 2>&1; then
      msg="Дизайн-система: в $f обнаружен хардкод цвета/стиля. Используйте токены темы (lib/core/theme/, Theme.of(context).colorScheme / .textTheme, ThemeExtension) вместо Colors.*, Color(0x..) и сырых TextStyle(. См. app/CLAUDE.md → «Дизайн-система»."
    elif [ -f "$f" ] && grep -nE '\b(ElevatedButton|FilledButton|TextButton|OutlinedButton|TextField|Card|ListTile|FilterChip|Chip)\(' "$f" >/dev/null 2>&1; then
      msg="Дизайн-система: в $f используется сырой Material-примитив. В lib/features/** берите компоненты из каталога lib/shared/components/ (AppButton, AppTextField, AppCard, AppListTile, AppChip, ...). См. docs/conventions/design-system.md."
    fi
    ;;
esac

case "$f" in
  */worker/src/Privacy/*|*PublishPricesStep.php|*PriceAnonymizer.php)
    msg="Инвариант приватности (зона C): $f — единственная точка отрыва наблюдений от пользователя. Убедитесь, что в prices/price_aggregates НЕ попадают user_id и family_id. См. docs/architecture/privacy.md."
    ;;
esac

if [ -n "$msg" ]; then
  jq -n --arg m "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
fi
exit 0
