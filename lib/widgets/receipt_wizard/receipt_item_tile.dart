import 'package:flutter/cupertino.dart';
import '../../models/receipt_item.dart';

class ReceiptItemTile extends StatelessWidget {
  const ReceiptItemTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.currencyCode,
    super.key,
  });

  final ReceiptItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final bool shouldShowSubtitle = _shouldShowSubtitle();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(12),
        onPressed: onEdit,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  if (shouldShowSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} × ${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${item.total.toStringAsFixed(2)} ${_getCurrencySymbol()}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDelete,
              child: Icon(
                CupertinoIcons.delete,
                size: 18,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowSubtitle() {
    // Показываем сабтайтл только для весовых товаров
    // Определяем по количеству - если количество меньше 1, то это весовой товар
    return item.quantity < 1.0;
  }

  String _getCurrencySymbol() {
    switch (currencyCode) {
      case 'RUB':
        return '₽';
      case 'BYN':
        return 'Br';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'PLN':
        return 'zł';
      case 'UAH':
        return '₴';
      case 'KZT':
        return '₸';
      case 'KGS':
        return 'с';
      case 'TJS':
        return 'SM';
      case 'UZS':
        return 'сўм';
      case 'AMD':
        return '֏';
      case 'GEL':
        return '₾';
      case 'AZN':
        return '₼';
      case 'MDL':
        return 'L';
      case 'BGN':
        return 'лв';
      case 'RON':
        return 'lei';
      case 'HUF':
        return 'Ft';
      case 'CZK':
        return 'Kč';
      case 'SEK':
        return 'kr';
      case 'NOK':
        return 'kr';
      case 'DKK':
        return 'kr';
      case 'CHF':
        return 'CHF';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'INR':
        return '₹';
      case 'BRL':
        return 'R\$';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return currencyCode ?? '₽';
    }
  }
}
