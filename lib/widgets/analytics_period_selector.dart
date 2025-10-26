import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics_period_data.dart';
import '../providers/analytics_provider.dart';

/// Виджет выбора периода аналитики
class AnalyticsPeriodSelector extends ConsumerWidget {
  const AnalyticsPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedAnalyticsPeriodProvider);

    return CupertinoSlidingSegmentedControl<AnalyticsPeriod>(
        groupValue: selectedPeriod,
        onValueChanged: (period) {
          if (period != null) {
            ref
                .read(selectedAnalyticsPeriodProvider.notifier)
                .setPeriod(period);
          }
        },
        children: {
          AnalyticsPeriod.week: _buildSegmentChild(
            context,
            'Неделя',
            selectedPeriod == AnalyticsPeriod.week,
          ),
          AnalyticsPeriod.month: _buildSegmentChild(
            context,
            'Месяц',
            selectedPeriod == AnalyticsPeriod.month,
          ),
          AnalyticsPeriod.year: _buildSegmentChild(
            context,
            'Год',
            selectedPeriod == AnalyticsPeriod.year,
          ),
          AnalyticsPeriod.allTime: _buildSegmentChild(
            context,
            'Всё',
            selectedPeriod == AnalyticsPeriod.allTime,
          ),
        },
    );
  }

  Widget _buildSegmentChild(
    BuildContext context,
    String text,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? CupertinoColors.label.resolveFrom(context)
              : CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}

