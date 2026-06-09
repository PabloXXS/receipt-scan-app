/// Назначение: экран раздела «Скан» — захват/предпросмотр/отправка фото чека.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components,
///   presentation/controllers/scan_controller.dart, presentation/widgets/*.
/// Ключевые типы: ScanScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';
import '../widgets/scan_capture_view.dart';
import '../widgets/scan_preview_view.dart';
import '../widgets/scan_success_view.dart';

/// Экран сканирования чека (фото). QR — отдельный цикл.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);

    final body = switch (state) {
      ScanIdle() => const ScanCaptureView(),
      ScanPreview(:final photoBytes) => ScanPreviewView(photoBytes: photoBytes),
      ScanSubmitting(:final photoBytes) =>
        ScanPreviewView(photoBytes: photoBytes, submitting: true),
      ScanSuccess() => const ScanSuccessView(),
      ScanError(:final failure, :final photoBytes) => photoBytes == null
          ? ScanCaptureView(error: failure.message)
          : ScanPreviewView(photoBytes: photoBytes, error: failure.message),
    };

    return AppScaffold(title: 'Сканировать', body: body);
  }
}
