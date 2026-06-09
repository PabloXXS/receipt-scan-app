/// Назначение: экран успешной отправки чека на обработку.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   presentation/controllers/scan_controller.dart.
/// Ключевые типы: ScanSuccessView.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';

/// Подтверждение отправки чека с кнопкой нового сканирования.
class ScanSuccessView extends ConsumerWidget {
  const ScanSuccessView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final controller = ref.read(scanControllerProvider.notifier);

    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppEmptyState(
            message: 'Чек отправлен на обработку.',
            icon: Icons.check_circle_outline,
          ),
          SizedBox(height: tokens.spaceXl),
          AppButton(
            label: 'Сканировать ещё',
            icon: Icons.add_a_photo,
            expanded: true,
            onPressed: controller.reset,
          ),
        ],
      ),
    );
  }
}
