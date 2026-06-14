/// Назначение: вид ревью распознанного чека — позиции, итог, сохранить/отмена.
///
/// Слой: presentation
/// Фича: scan
/// Зависимости: flutter, flutter_riverpod, shared/components, core/theme,
///   domain/entities/receipt_draft.dart, presentation/controllers/scan_controller.dart.
/// Ключевые типы: ReceiptReviewView.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt_draft.dart';
import '../controllers/scan_controller.dart';

/// Список распознанных позиций с возможностью удалить строку и сохранить чек.
class ReceiptReviewView extends ConsumerWidget {
  const ReceiptReviewView({
    super.key,
    required this.draft,
    this.saving = false,
    this.error,
  });

  final ReceiptDraft draft;
  final bool saving;
  final String? error;

  // Валюта для отображения до сохранения (фактическую проставит триггер по стране).
  static const _currency = 'BYN';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final controller = ref.read(scanControllerProvider.notifier);

    return Column(
      children: [
        if (!draft.totalMatches)
          Padding(
            padding: EdgeInsets.all(tokens.spaceMd),
            child: const AppBadge(
              label: 'Сумма позиций не сходится с итогом — проверьте',
              tone: AppBadgeTone.warning,
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: draft.items.length,
            itemBuilder: (context, i) {
              final it = draft.items[i];
              return Dismissible(
                key: ValueKey('item_${i}_${it.rawName}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => controller.removeItem(i),
                background: ColoredBox(color: scheme.errorContainer),
                child: AppListTile(
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
                  MoneyText(draft.total ?? draft.itemsSum,
                      currencyCode: _currency),
                ],
              ),
              if (error != null) ...[
                SizedBox(height: tokens.spaceSm),
                Text(error!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: scheme.error)),
              ],
              SizedBox(height: tokens.spaceLg),
              AppButton(
                label: 'Сохранить',
                icon: Icons.save_alt,
                expanded: true,
                loading: saving,
                onPressed: saving ? null : controller.save,
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
