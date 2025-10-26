import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/analytics_period_data.dart';
import '../repositories/analytics_repository.dart';

part 'analytics_provider.g.dart';

/// Провайдер для выбранного периода аналитики
@riverpod
class SelectedAnalyticsPeriod extends _$SelectedAnalyticsPeriod {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.month;

  void setPeriod(AnalyticsPeriod period) {
    state = period;
  }
}

/// Провайдер для данных аналитики за выбранный период
@riverpod
class TimeBasedAnalytics extends _$TimeBasedAnalytics {
  @override
  FutureOr<AnalyticsPeriodData> build() async {
    // Следим за изменениями выбранного периода
    final period = ref.watch(selectedAnalyticsPeriodProvider);
    
    return ref
        .read(analyticsRepositoryProvider)
        .getAnalyticsForPeriod(period);
  }

  /// Обновить данные
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

