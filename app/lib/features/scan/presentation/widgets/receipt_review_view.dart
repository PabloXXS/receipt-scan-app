/// Назначение: вид ревью серверных позиций чека — подсветка confidence, подтвердить/отмена.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   domain/entities/scanned_item.dart, presentation/controllers/scan_controller.dart.
/// Ключевые типы: ReceiptReviewView.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/scanned_item.dart';
import '../controllers/scan_controller.dart';

/// Список распознанных сервером позиций: подсветка сомнительных, удаление, подтверждение.
class ReceiptReviewView extends ConsumerWidget {
  const ReceiptReviewView({
    super.key,
    required this.items,
    this.saving = false,
    this.error,
  });

  final List<ScannedItem> items;
  final bool saving;
  final String? error;

  // Валюта для отображения до подтверждения (фактическую проставит триггер по стране).
  static const _currency = 'BYN';

  double get _sum => items.fold(0, (a, i) => a + i.sum);
  bool get _hasLowConfidence => items.any((i) => i.lowConfidence);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(scanControllerProvider.notifier);

    return Column(
      children: [
        if (_hasLowConfidence)
          Padding(
            padding: EdgeInsets.all(tokens.spaceMd),
            child: const AppBadge(
              label: 'Часть позиций распознана неуверенно — проверьте',
              tone: AppBadgeTone.warning,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return Dismissible(
                key: ValueKey('item_${i}_${it.rawName}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => controller.removeItem(i),
                background: ColoredBox(color: scheme.errorContainer),
                child: AppListTile(
                  leading: it.lowConfidence
                      ? Icon(Icons.help_outline, color: scheme.tertiary)
                      : null,
                  title: it.rawName,
                  subtitle: '${it.qty} × ${it.unitPrice}',
                  trailing: MoneyText(it.sum, currencyCode: _currency),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Итого', style: textTheme.titleMedium),
                  MoneyText(_sum, currencyCode: _currency),
                ],
              ),
              if (error != null) ...[
                SizedBox(height: tokens.spaceSm),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: scheme.error),
                ),
              ],
              SizedBox(height: tokens.spaceLg),
              AppButton(
                label: 'Подтвердить',
                icon: Icons.check,
                expanded: true,
                loading: saving,
                onPressed: saving ? null : controller.confirm,
              ),
              SizedBox(height: tokens.spaceSm),
              AppButton(
                label: 'Отмена',
                variant: AppButtonVariant.text,
                expanded: true,
                onPressed: saving ? null : controller.reset,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
