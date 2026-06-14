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
import '../../domain/entities/receipt_details.dart';
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
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: EdgeInsets.all(tokens.spaceMd),
      children: [
        Row(
          children: [
            ReceiptPhotoThumbnail(photoPath: r.photoPath, size: 72),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.storeName ?? 'Магазин не определён',
                      style: theme.textTheme.titleLarge),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    DateFormat.yMMMMd(locale).add_Hm().format(r.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ReceiptStatusBadge(status: r.status),
          ],
        ),
        SizedBox(height: tokens.spaceLg),
        if (r.total != null && r.currency != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого', style: theme.textTheme.titleMedium),
              MoneyText(r.total!,
                  currencyCode: r.currency!,
                  style: theme.textTheme.titleMedium),
            ],
          ),
        const Divider(height: 32),
        Text('Позиции', style: theme.textTheme.titleMedium),
        SizedBox(height: tokens.spaceSm),
        if (details.items.isEmpty)
          Text('Позиции ещё не распознаны',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
        else
          ...details.items.map(
            (it) => Padding(
              padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text(it.rawName, style: theme.textTheme.bodyMedium)),
                  SizedBox(width: tokens.spaceSm),
                  Text('${_qty(it.qty)} × ',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (r.currency != null)
                    MoneyText(it.sum,
                        currencyCode: r.currency!,
                        style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _qty(double qty) =>
      qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
}
