/// Назначение: текстовое поле дизайн-системы с лейблом, ошибкой и иконкой.
///
/// Слой: shared/components
/// Зависимости: flutter material, core/theme/app_tokens.dart.
/// Ключевые типы: AppTextField.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Поле ввода с единым оформлением (M3 outlined).
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.onChanged,
    this.errorText,
    this.hintText,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final String? hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
      ),
    );
  }
}
