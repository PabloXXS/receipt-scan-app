import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/analytics_period_data.dart';

/// Виджет графика трендов расходов
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.trendPoints,
    required this.period,
  });

  final List<TrendPoint> trendPoints;
  final AnalyticsPeriod period;

  @override
  Widget build(BuildContext context) {
    if (trendPoints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Недостаточно данных для графика',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    final maxAmount = trendPoints
        .map((p) => p.amount)
        .reduce((a, b) => a > b ? a : b);
    final minAmount = trendPoints
        .map((p) => p.amount)
        .reduce((a, b) => a < b ? a : b);

    // Добавляем небольшой отступ сверху и снизу
    final yMax = maxAmount * 1.1;
    final yMin = minAmount > 0 ? 0.0 : minAmount * 1.1;

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 16, right: 16, bottom: 8, left: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (yMax - yMin) / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color:
                    CupertinoColors.separator.resolveFrom(context),
                strokeWidth: 0.5,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateXInterval(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trendPoints.length) {
                    return const SizedBox.shrink();
                  }
                  return _buildBottomTitle(context, trendPoints[index].date);
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: (yMax - yMin) / 4,
                getTitlesWidget: (value, meta) {
                  return _buildLeftTitle(context, value);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trendPoints.length - 1).toDouble(),
          minY: yMin,
          maxY: yMax,
          lineBarsData: [
            LineChartBarData(
              spots: trendPoints
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.amount))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: CupertinoColors.systemBlue.resolveFrom(context),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: CupertinoColors.systemBlue.resolveFrom(context),
                    strokeWidth: 2,
                    strokeColor:
                        CupertinoColors.systemBackground.resolveFrom(context),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CupertinoColors.systemBlue
                        .resolveFrom(context)
                        .withOpacity(0.2),
                    CupertinoColors.systemBlue
                        .resolveFrom(context)
                        .withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  CupertinoColors.tertiarySystemBackground
                      .resolveFrom(context)
                      .withOpacity(0.95),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final point = trendPoints[spot.x.toInt()];
                  final dateStr = DateFormat('d MMM', 'ru').format(point.date);
                  return LineTooltipItem(
                    '$dateStr\n${point.amount.toStringAsFixed(2)} ₽\n${point.receiptCount} чек.',
                    TextStyle(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(BuildContext context, DateTime date) {
    String label;
    switch (period) {
      case AnalyticsPeriod.week:
        label = DateFormat('EEE', 'ru').format(date);
      case AnalyticsPeriod.month:
        label = DateFormat('d', 'ru').format(date);
      case AnalyticsPeriod.quarter:
      case AnalyticsPeriod.year:
        label = DateFormat('MMM', 'ru').format(date);
      case AnalyticsPeriod.allTime:
        label = DateFormat('MMM yy', 'ru').format(date);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildLeftTitle(BuildContext context, double value) {
    String label;
    if (value >= 1000) {
      label = '${(value / 1000).toStringAsFixed(1)}k';
    } else {
      label = value.toStringAsFixed(0);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        label,
        style: TextStyle(
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
          fontSize: 11,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  double _calculateXInterval() {
    // Показываем не больше 7 меток на оси X
    final pointsCount = trendPoints.length;
    if (pointsCount <= 7) return 1;
    return (pointsCount / 7).ceilToDouble();
  }
}

