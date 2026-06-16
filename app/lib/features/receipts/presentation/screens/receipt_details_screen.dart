/// Назначение: экран деталей чека — шапка (магазин/сумма/дата/статус), фото, позиции.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, intl, core/error/failure.dart,
///   core/theme/app_tokens.dart, shared/components, controllers/receipt_details_controller.dart,
///   widgets (thumbnail/status badge), domain/entities.
/// Ключевые типы: ReceiptDetailsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/entities/receipt_item.dart';
import '../controllers/receipt_details_controller.dart';
import '../widgets/receipt_photo_thumbnail.dart';
import '../widgets/receipt_status_badge.dart';

/// Детальный просмотр чека по [id].
class ReceiptDetailsScreen extends ConsumerWidget {
  const ReceiptDetailsScreen({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptDetailsProvider(id));
    final body = async.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(
        message: e is Failure ? e.message : 'Не удалось загрузить чек',
        onRetry: () => ref.invalidate(receiptDetailsProvider(id)),
      ),
      data: (details) => _DetailsBody(details: details),
    );
    return AppScaffold(title: 'Чек', body: body);
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.details});

  final ReceiptDetails details;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final r = details.receipt;

    return ListView(
      padding: EdgeInsets.all(tokens.spaceMd),
      children: [
        _HeaderCard(receipt: r),
        SizedBox(height: tokens.spaceLg),
        Padding(
          padding: EdgeInsets.only(left: tokens.spaceXs, right: tokens.spaceXs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Позиции', style: theme.textTheme.titleMedium),
              if (details.items.isNotEmpty)
                Text(
                  '${details.items.length}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        if (details.items.isEmpty)
          AppCard(
            child: Text(
              'Позиции ещё не распознаны',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
            child: Column(
              children: [
                for (final (i, it) in details.items.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: tokens.spaceMd,
                      endIndent: tokens.spaceMd,
                    ),
                  _ItemRow(item: it, currency: r.currency),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Шапка: фото, магазин, дата, статус и итоговая сумма.
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReceiptPhotoThumbnail(photoPath: receipt.photoPath, size: 64),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.storeName ?? 'Магазин не определён',
                        style: theme.textTheme.titleLarge),
                    SizedBox(height: tokens.spaceXs),
                    Text(
                      DateFormat.yMMMMd(locale).add_Hm().format(
                            receipt.purchasedAt ?? receipt.createdAt,
                          ),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              ReceiptStatusBadge(status: receipt.status),
            ],
          ),
          if (receipt.total != null && receipt.currency != null) ...[
            Divider(height: tokens.spaceXl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Итого', style: theme.textTheme.titleMedium),
                MoneyText(
                  receipt.total!,
                  currencyCode: receipt.currency!,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Одна позиция чека: название, опциональная строка «кол-во × цена» и сумма.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currency});

  final ReceiptItem item;
  final String? currency;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    // Строку «кол-во × цена» показываем только когда она несёт смысл:
    // для штучной единицы (qty = 1) сумма уже всё объясняет.
    final showUnit = item.qty != 1;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.rawName, style: theme.textTheme.bodyMedium),
                if (showUnit && currency != null) ...[
                  SizedBox(height: tokens.spaceXs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_qty(item.qty)} × ', style: muted),
                      MoneyText(
                        item.unitPrice,
                        currencyCode: currency!,
                        style: muted,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          if (currency != null)
            MoneyText(
              item.sum,
              currencyCode: currency!,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  String _qty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}
