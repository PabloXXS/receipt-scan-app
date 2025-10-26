import 'package:flutter/cupertino.dart';
import '../models/analytics_period_data.dart';

/// Виджет сравнения текущего периода с предыдущим
class PeriodComparisonCard extends StatelessWidget {
  const PeriodComparisonCard({
    super.key,
    required this.comparison,
  });

  final PeriodComparison comparison;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Сравнение с предыдущим периодом',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          _buildComparisonItem(
            context,
            label: 'Сумма',
            currentValue: comparison.currentAmount,
            changePercent: comparison.amountChangePercent,
            isIncrease: comparison.amountIncreased,
            isCurrency: true,
          ),
          _buildComparisonItem(
            context,
            label: 'Количество чеков',
            currentValue: comparison.currentReceiptCount.toDouble(),
            changePercent: comparison.receiptCountChangePercent,
            isIncrease: comparison.receiptCountIncreased,
            isCurrency: false,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(
    BuildContext context, {
    required String label,
    required double currentValue,
    required double changePercent,
    required bool isIncrease,
    required bool isCurrency,
  }) {
    final changeColor = isIncrease
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemGreen.resolveFrom(context);

    final changeIcon = isIncrease
        ? CupertinoIcons.arrow_up_right
        : CupertinoIcons.arrow_down_right;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrency
                      ? '${currentValue.toStringAsFixed(2)} ₽'
                      : currentValue.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          if (changePercent.abs() > 0.01) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    changeIcon,
                    size: 14,
                    color: changeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${changePercent.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

