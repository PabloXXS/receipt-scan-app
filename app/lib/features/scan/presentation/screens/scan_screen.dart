/// Назначение: экран раздела «Скан» — захват/предпросмотр/отправка фото чека.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components,
///   presentation/controllers/scan_controller.dart, presentation/widgets/*.
/// Ключевые типы: ScanScreen.
///
/// TODO(Task-10): переписать под новые состояния OCR-потока (ScanReview/ScanSaved).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';
import '../widgets/scan_capture_view.dart';
import '../widgets/scan_success_view.dart';

/// Экран сканирования чека (фото). QR — отдельный цикл.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);

    final body = switch (state) {
      ScanIdle() => const ScanCaptureView(),
      ScanRecognizing() => const AppLoader(),
      ScanReview() => const ScanCaptureView(), // TODO(Task-10): ScanReviewView
      ScanSaving() => const AppLoader(),
      ScanSaved() => const ScanSuccessView(),
      ScanError(:final failure) => ScanCaptureView(error: failure.message),
    };

    return AppScaffold(title: 'Сканировать', body: body);
  }
}
