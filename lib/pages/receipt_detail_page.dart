import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';
import '../providers/receipts_provider.dart';

class ReceiptDetailPage extends ConsumerWidget {
  const ReceiptDetailPage({
    super.key,
    required this.receiptId,
  });

  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(receiptDetailsProvider(receiptId));

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            CupertinoColors.systemGroupedBackground.resolveFrom(context),
        middle: detailsAsync.when(
          data: (data) {
            final receipt = data.$1;
            return Text(receipt.merchantName ?? 'Чек');
          },
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Чек'),
        ),
      ),
      child: detailsAsync.when(
        data: (data) {
          final receipt = data.$1;
          final items = data.$2;
          return _ReceiptDetailContent(
            receipt: receipt,
            items: items,
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.systemRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки',
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.label.resolveFrom(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptDetailContent extends StatelessWidget {
  const _ReceiptDetailContent({
    required this.receipt,
    required this.items,
  });

  final Receipt receipt;
  final List<ReceiptItem> items;

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final date = receipt.purchaseDate ?? receipt.createdAt;
    final time = receipt.purchaseTime;

    return ListView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      children: [
        // Информация о чеке
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              if (receipt.merchantName != null)
                _InfoRow(
                  label: 'Магазин',
                  value: receipt.merchantName!,
                ),
              _InfoRow(
                label: 'Дата',
                value: time != null
                    ? '${_formatDate(date)}, ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                    : _formatDate(date),
              ),
              _InfoRow(
                label: 'Сумма',
                value: '${receipt.total.toStringAsFixed(2)} ${receipt.currency}',
                isLast: true,
              ),
            ],
          ),
        ),

        // Заголовок позиций
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
          child: Text(
            'ПОЗИЦИИ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),

        // Список позиций
        if (items.isEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Нет позиций',
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  _ItemRow(
                    item: items[i],
                    isLast: i == items.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    this.isLast = false,
  });

  final ReceiptItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                if (item.categoryName != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.categoryName!,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.total.toStringAsFixed(2)} ₽',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 3)} × ${item.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

