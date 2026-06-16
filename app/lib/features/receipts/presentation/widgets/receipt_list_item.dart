/// Назначение: строка списка чеков со свайп-удалением (slidable) и тапом.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_slidable, intl, core/theme/app_tokens.dart,
///   shared/components, domain/entities/receipt.dart, widgets/receipt_photo_thumbnail.dart.
/// Ключевые типы: ReceiptListItem.
library;

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt.dart';
import 'receipt_photo_thumbnail.dart';

/// Фолбэк-название, когда магазин ещё не распознан воркером.
const String _storeFallback = 'Магазин не определён';

/// Строка чека: фото, магазин, сумма, дата; свайп → удаление.
class ReceiptListItem extends StatelessWidget {
  const ReceiptListItem({
    required this.receipt,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final Receipt receipt;
  final VoidCallback onTap;

  /// Подтверждённое удаление (диалог уже пройден).
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Slidable(
      key: ValueKey(receipt.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (ctx) => _confirmAndDelete(ctx),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
            icon: Icons.delete_outline,
            label: 'Удалить',
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
        ],
      ),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            ReceiptPhotoThumbnail(photoPath: receipt.photoPath),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.storeName ?? _storeFallback,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  if (receipt.total != null && receipt.currency != null)
                    MoneyText(
                      receipt.total!,
                      currencyCode: receipt.currency!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    DateFormat.yMMMd(
                      Localizations.localeOf(context).toString(),
                    ).add_Hm().format(receipt.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить чек?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          AppButton(
            label: 'Отмена',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: 'Удалить',
            variant: AppButtonVariant.destructive,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) await onDelete();
  }
}
