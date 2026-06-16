/// Назначение: экран «Скан» — захват фото → распознавание → ревью → сохранение.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   presentation/controllers/scan_controller.dart, presentation/widgets/*.
/// Ключевые типы: ScanScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/scan_controller.dart';
import '../widgets/receipt_review_view.dart';
import '../widgets/scan_capture_view.dart';

/// Экран скана чека (фото → OCR → позиции).
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);

    final body = switch (state) {
      ScanIdle() => const ScanCaptureView(),
      ScanError() => ScanCaptureView(error: state.failure.message),
      ScanUploading() => const AppLoader(),
      ScanProcessing() => const _ProcessingView(),
      ScanReview(:final items) => ReceiptReviewView(items: items),
      ScanConfirming(:final items) =>
        ReceiptReviewView(items: items, saving: true),
      ScanSaved() => const _SavedView(),
    };

    return AppScaffold(title: 'Сканировать', body: body);
  }
}

/// Ожидание результата серверного OCR.
class _ProcessingView extends StatelessWidget {
  const _ProcessingView();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: EdgeInsets.all(tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Распознаём чек…',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _SavedView extends ConsumerWidget {
  const _SavedView();

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
            message: 'Чек сохранён.',
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
