import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/analytics_period_data.dart';

part 'analytics_repository.g.dart';

@riverpod
AnalyticsRepository analyticsRepository(Ref ref) {
  return AnalyticsRepository();
}

class AnalyticsRepository {
  /// Получить данные аналитики за период
  Future<AnalyticsPeriodData> getAnalyticsForPeriod(
    AnalyticsPeriod period,
  ) async {
    final client = Supabase.instance.client;
    final now = DateTime.now();

    // Вычисляем границы периода
    final (startDate, endDate) = _calculatePeriodBounds(period, now);

    // Получаем чеки за текущий период
    final currentReceipts = await _fetchReceiptsForDateRange(
      client,
      startDate,
      endDate,
    );

    // Вычисляем границы предыдущего периода для сравнения
    final previousPeriodStart = _getPreviousPeriodStart(period, startDate);
    final previousPeriodEnd = startDate.subtract(const Duration(seconds: 1));

    // Получаем чеки за предыдущий период
    final previousReceipts = await _fetchReceiptsForDateRange(
      client,
      previousPeriodStart,
      previousPeriodEnd,
    );

    // Рассчитываем общую статистику
    final totalAmount = currentReceipts.fold<double>(
      0.0,
      (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
    );
    final totalReceipts = currentReceipts.length;
    final avgReceiptAmount =
        totalReceipts > 0 ? totalAmount / totalReceipts : 0.0;

    // Строим точки для тренда (группируем по дням)
    final trendPoints = _buildTrendPoints(currentReceipts, startDate, endDate);

    // Сравнение с предыдущим периодом
    final previousTotalAmount = previousReceipts.fold<double>(
      0.0,
      (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
    );
    final comparison = PeriodComparison(
      currentAmount: totalAmount,
      previousAmount: previousTotalAmount,
      currentReceiptCount: totalReceipts,
      previousReceiptCount: previousReceipts.length,
    );

    return AnalyticsPeriodData(
      period: period,
      totalAmount: totalAmount,
      totalReceipts: totalReceipts,
      avgReceiptAmount: avgReceiptAmount,
      trendPoints: trendPoints,
      comparison: comparison,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Получить чеки за диапазон дат
  Future<List<Map<String, dynamic>>> _fetchReceiptsForDateRange(
    SupabaseClient client,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Используем purchase_date если есть, иначе created_at
    final response = await client
        .from('receipts')
        .select('id, total, purchase_date, created_at')
        .eq('is_deleted', false)
        .gte(
          'created_at',
          startDate.toIso8601String(),
        )
        .lte(
          'created_at',
          endDate.toIso8601String(),
        )
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Вычислить границы периода
  (DateTime, DateTime) _calculatePeriodBounds(
    AnalyticsPeriod period,
    DateTime now,
  ) {
    final endDate = now;
    DateTime startDate;

    switch (period) {
      case AnalyticsPeriod.week:
        startDate = now.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        startDate = now.subtract(const Duration(days: 30));
      case AnalyticsPeriod.quarter:
        startDate = now.subtract(const Duration(days: 90));
      case AnalyticsPeriod.year:
        startDate = now.subtract(const Duration(days: 365));
      case AnalyticsPeriod.allTime:
        // Для всего времени берем дату из далекого прошлого
        startDate = DateTime(2000);
    }

    return (startDate, endDate);
  }

  /// Получить начало предыдущего периода
  DateTime _getPreviousPeriodStart(
    AnalyticsPeriod period,
    DateTime currentStart,
  ) {
    switch (period) {
      case AnalyticsPeriod.week:
        return currentStart.subtract(const Duration(days: 7));
      case AnalyticsPeriod.month:
        return currentStart.subtract(const Duration(days: 30));
      case AnalyticsPeriod.quarter:
        return currentStart.subtract(const Duration(days: 90));
      case AnalyticsPeriod.year:
        return currentStart.subtract(const Duration(days: 365));
      case AnalyticsPeriod.allTime:
        return DateTime(2000);
    }
  }

  /// Построить точки тренда по дням
  List<TrendPoint> _buildTrendPoints(
    List<Map<String, dynamic>> receipts,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (receipts.isEmpty) return [];

    // Группируем чеки по дням
    final Map<String, List<Map<String, dynamic>>> receiptsByDay = {};

    for (final receipt in receipts) {
      final dateStr = receipt['purchase_date'] as String? ??
          receipt['created_at'] as String;
      final date = DateTime.parse(dateStr);
      final dayKey = _formatDateKey(date);

      receiptsByDay.putIfAbsent(dayKey, () => []);
      receiptsByDay[dayKey]!.add(receipt);
    }

    // Создаем точки для каждого дня с данными
    final points = <TrendPoint>[];
    for (final entry in receiptsByDay.entries) {
      final date = DateTime.parse(entry.key);
      final dayReceipts = entry.value;
      final amount = dayReceipts.fold<double>(
        0.0,
        (sum, receipt) => sum + (receipt['total'] as num).toDouble(),
      );

      points.add(TrendPoint(
        date: date,
        amount: amount,
        receiptCount: dayReceipts.length,
      ));
    }

    // Сортируем по дате
    points.sort((a, b) => a.date.compareTo(b.date));

    return points;
  }

  /// Форматировать дату для ключа (YYYY-MM-DD)
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

