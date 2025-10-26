import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_period_data.freezed.dart';
part 'analytics_period_data.g.dart';

/// Периоды для аналитики
enum AnalyticsPeriod {
  @JsonValue('week')
  week,
  @JsonValue('month')
  month,
  @JsonValue('quarter')
  quarter,
  @JsonValue('year')
  year,
  @JsonValue('all_time')
  allTime,
}

extension AnalyticsPeriodExtension on AnalyticsPeriod {
  String get displayName {
    switch (this) {
      case AnalyticsPeriod.week:
        return 'Неделя';
      case AnalyticsPeriod.month:
        return 'Месяц';
      case AnalyticsPeriod.quarter:
        return 'Квартал';
      case AnalyticsPeriod.year:
        return 'Год';
      case AnalyticsPeriod.allTime:
        return 'Всё время';
    }
  }

  int get daysCount {
    switch (this) {
      case AnalyticsPeriod.week:
        return 7;
      case AnalyticsPeriod.month:
        return 30;
      case AnalyticsPeriod.quarter:
        return 90;
      case AnalyticsPeriod.year:
        return 365;
      case AnalyticsPeriod.allTime:
        return 0; // Без ограничений
    }
  }
}

/// Данные для одной точки на графике тренда
@freezed
class TrendPoint with _$TrendPoint {
  const factory TrendPoint({
    required DateTime date,
    required double amount,
    required int receiptCount,
  }) = _TrendPoint;

  factory TrendPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendPointFromJson(json);
}

/// Сравнение текущего периода с предыдущим
@freezed
class PeriodComparison with _$PeriodComparison {
  const factory PeriodComparison({
    required double currentAmount,
    required double previousAmount,
    required int currentReceiptCount,
    required int previousReceiptCount,
  }) = _PeriodComparison;

  factory PeriodComparison.fromJson(Map<String, dynamic> json) =>
      _$PeriodComparisonFromJson(json);
}

extension PeriodComparisonExtension on PeriodComparison {
  double get amountChangePercent {
    if (previousAmount == 0) return 0;
    return ((currentAmount - previousAmount) / previousAmount) * 100;
  }

  double get receiptCountChangePercent {
    if (previousReceiptCount == 0) return 0;
    return ((currentReceiptCount - previousReceiptCount) /
            previousReceiptCount) *
        100;
  }

  bool get amountIncreased => currentAmount > previousAmount;
  bool get receiptCountIncreased => currentReceiptCount > previousReceiptCount;
}

/// Полные данные аналитики за период
@freezed
class AnalyticsPeriodData with _$AnalyticsPeriodData {
  const factory AnalyticsPeriodData({
    required AnalyticsPeriod period,
    required double totalAmount,
    required int totalReceipts,
    required double avgReceiptAmount,
    required List<TrendPoint> trendPoints,
    required PeriodComparison? comparison,
    required DateTime startDate,
    required DateTime endDate,
  }) = _AnalyticsPeriodData;

  factory AnalyticsPeriodData.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsPeriodDataFromJson(json);
}

