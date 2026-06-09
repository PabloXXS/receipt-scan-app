/// Назначение: кнопка дизайн-системы с вариантами и состоянием загрузки.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppButton, AppButtonVariant.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Визуальный вариант [AppButton].
enum AppButtonVariant { primary, secondary, text, destructive }

/// Кнопка дизайн-системы. Оборачивает M3-кнопки, единый радиус из токенов.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Растягивать ли кнопку по ширине родителя.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = loading ? null : onPressed;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
    );

    final spinnerColor = switch (variant) {
      AppButtonVariant.primary => scheme.onPrimary,
      AppButtonVariant.secondary => scheme.primary,
      AppButtonVariant.text => scheme.primary,
      AppButtonVariant.destructive => scheme.onError,
    };

    final child = loading
        ? SizedBox(
            height: 18,
            width: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: spinnerColor),
          )
        : _label(context);

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(shape: shape),
          child: child,
        ),
      AppButtonVariant.destructive => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            shape: shape,
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          child: child,
        ),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _label(BuildContext context) {
    if (icon == null) return Text(label);
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        SizedBox(width: tokens.spaceSm),
        Text(label),
      ],
    );
  }
}
