/// Назначение: предпросмотр выбранного фото с действиями отправить/переснять.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: dart:typed_data, flutter, flutter_riverpod, shared/components,
///   core/theme, presentation/controllers/scan_controller.dart.
/// Ключевые типы: ScanPreviewView.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';

/// Предпросмотр фото. [submitting] — идёт отправка; [error] — текст ошибки отправки.
class ScanPreviewView extends ConsumerWidget {
  const ScanPreviewView({
    super.key,
    required this.photoBytes,
    this.submitting = false,
    this.error,
  });

  final Uint8List photoBytes;
  final bool submitting;
  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(scanControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Image.memory(
                photoBytes,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          if (error != null) ...[
            SizedBox(height: tokens.spaceMd),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: scheme.error),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          AppButton(
            label: 'Отправить',
            icon: Icons.cloud_upload,
            expanded: true,
            loading: submitting,
            onPressed: submitting ? null : controller.submit,
          ),
          SizedBox(height: tokens.spaceSm),
          AppButton(
            label: 'Переснять',
            variant: AppButtonVariant.text,
            expanded: true,
            onPressed: submitting ? null : controller.retake,
          ),
        ],
      ),
    );
  }
}
