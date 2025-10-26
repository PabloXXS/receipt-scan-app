// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_period_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TrendPointImpl _$$TrendPointImplFromJson(Map<String, dynamic> json) =>
    _$TrendPointImpl(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      receiptCount: (json['receiptCount'] as num).toInt(),
    );

Map<String, dynamic> _$$TrendPointImplToJson(_$TrendPointImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'amount': instance.amount,
      'receiptCount': instance.receiptCount,
    };

_$PeriodComparisonImpl _$$PeriodComparisonImplFromJson(
        Map<String, dynamic> json) =>
    _$PeriodComparisonImpl(
      currentAmount: (json['currentAmount'] as num).toDouble(),
      previousAmount: (json['previousAmount'] as num).toDouble(),
      currentReceiptCount: (json['currentReceiptCount'] as num).toInt(),
      previousReceiptCount: (json['previousReceiptCount'] as num).toInt(),
    );

Map<String, dynamic> _$$PeriodComparisonImplToJson(
        _$PeriodComparisonImpl instance) =>
    <String, dynamic>{
      'currentAmount': instance.currentAmount,
      'previousAmount': instance.previousAmount,
      'currentReceiptCount': instance.currentReceiptCount,
      'previousReceiptCount': instance.previousReceiptCount,
    };

_$AnalyticsPeriodDataImpl _$$AnalyticsPeriodDataImplFromJson(
        Map<String, dynamic> json) =>
    _$AnalyticsPeriodDataImpl(
      period: $enumDecode(_$AnalyticsPeriodEnumMap, json['period']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalReceipts: (json['totalReceipts'] as num).toInt(),
      avgReceiptAmount: (json['avgReceiptAmount'] as num).toDouble(),
      trendPoints: (json['trendPoints'] as List<dynamic>)
          .map((e) => TrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      comparison: json['comparison'] == null
          ? null
          : PeriodComparison.fromJson(
              json['comparison'] as Map<String, dynamic>),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
    );

Map<String, dynamic> _$$AnalyticsPeriodDataImplToJson(
        _$AnalyticsPeriodDataImpl instance) =>
    <String, dynamic>{
      'period': _$AnalyticsPeriodEnumMap[instance.period]!,
      'totalAmount': instance.totalAmount,
      'totalReceipts': instance.totalReceipts,
      'avgReceiptAmount': instance.avgReceiptAmount,
      'trendPoints': instance.trendPoints,
      'comparison': instance.comparison,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
    };

const _$AnalyticsPeriodEnumMap = {
  AnalyticsPeriod.week: 'week',
  AnalyticsPeriod.month: 'month',
  AnalyticsPeriod.quarter: 'quarter',
  AnalyticsPeriod.year: 'year',
  AnalyticsPeriod.allTime: 'all_time',
};
