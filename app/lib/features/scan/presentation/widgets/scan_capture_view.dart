/// Назначение: вид выбора способа захвата чека (камера/галерея).
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   presentation/controllers/scan_controller.dart.
/// Ключевые типы: ScanCaptureView.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';

/// Экран выбора источника фото. [error] — текст ошибки выбора (если была).
class ScanCaptureView extends ConsumerWidget {
  const ScanCaptureView({super.key, this.error});

  final String? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final controller = ref.read(scanControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (error != null)
            AppErrorView(message: error!)
          else
            const AppEmptyState(
              message: 'Сфотографируйте чек или выберите фото из галереи.',
              icon: Icons.receipt_long,
            ),
          SizedBox(height: tokens.spaceXl),
          AppButton(
            label: 'Сфотографировать',
            icon: Icons.photo_camera,
            expanded: true,
            onPressed: controller.pickFromCamera,
          ),
          SizedBox(height: tokens.spaceSm),
          AppButton(
            label: 'Из галереи',
            icon: Icons.photo_library,
            variant: AppButtonVariant.secondary,
            expanded: true,
            onPressed: controller.pickFromGallery,
          ),
        ],
      ),
    );
  }
}
