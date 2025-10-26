// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_period_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrendPoint _$TrendPointFromJson(Map<String, dynamic> json) {
  return _TrendPoint.fromJson(json);
}

/// @nodoc
mixin _$TrendPoint {
  DateTime get date => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  int get receiptCount => throw _privateConstructorUsedError;

  /// Serializes this TrendPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrendPointCopyWith<TrendPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrendPointCopyWith<$Res> {
  factory $TrendPointCopyWith(
          TrendPoint value, $Res Function(TrendPoint) then) =
      _$TrendPointCopyWithImpl<$Res, TrendPoint>;
  @useResult
  $Res call({DateTime date, double amount, int receiptCount});
}

/// @nodoc
class _$TrendPointCopyWithImpl<$Res, $Val extends TrendPoint>
    implements $TrendPointCopyWith<$Res> {
  _$TrendPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? amount = null,
    Object? receiptCount = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      receiptCount: null == receiptCount
          ? _value.receiptCount
          : receiptCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrendPointImplCopyWith<$Res>
    implements $TrendPointCopyWith<$Res> {
  factory _$$TrendPointImplCopyWith(
          _$TrendPointImpl value, $Res Function(_$TrendPointImpl) then) =
      __$$TrendPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, double amount, int receiptCount});
}

/// @nodoc
class __$$TrendPointImplCopyWithImpl<$Res>
    extends _$TrendPointCopyWithImpl<$Res, _$TrendPointImpl>
    implements _$$TrendPointImplCopyWith<$Res> {
  __$$TrendPointImplCopyWithImpl(
      _$TrendPointImpl _value, $Res Function(_$TrendPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? amount = null,
    Object? receiptCount = null,
  }) {
    return _then(_$TrendPointImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      receiptCount: null == receiptCount
          ? _value.receiptCount
          : receiptCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrendPointImpl implements _TrendPoint {
  const _$TrendPointImpl(
      {required this.date, required this.amount, required this.receiptCount});

  factory _$TrendPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrendPointImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double amount;
  @override
  final int receiptCount;

  @override
  String toString() {
    return 'TrendPoint(date: $date, amount: $amount, receiptCount: $receiptCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrendPointImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.receiptCount, receiptCount) ||
                other.receiptCount == receiptCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, amount, receiptCount);

  /// Create a copy of TrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrendPointImplCopyWith<_$TrendPointImpl> get copyWith =>
      __$$TrendPointImplCopyWithImpl<_$TrendPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrendPointImplToJson(
      this,
    );
  }
}

abstract class _TrendPoint implements TrendPoint {
  const factory _TrendPoint(
      {required final DateTime date,
      required final double amount,
      required final int receiptCount}) = _$TrendPointImpl;

  factory _TrendPoint.fromJson(Map<String, dynamic> json) =
      _$TrendPointImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get amount;
  @override
  int get receiptCount;

  /// Create a copy of TrendPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrendPointImplCopyWith<_$TrendPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PeriodComparison _$PeriodComparisonFromJson(Map<String, dynamic> json) {
  return _PeriodComparison.fromJson(json);
}

/// @nodoc
mixin _$PeriodComparison {
  double get currentAmount => throw _privateConstructorUsedError;
  double get previousAmount => throw _privateConstructorUsedError;
  int get currentReceiptCount => throw _privateConstructorUsedError;
  int get previousReceiptCount => throw _privateConstructorUsedError;

  /// Serializes this PeriodComparison to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PeriodComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeriodComparisonCopyWith<PeriodComparison> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeriodComparisonCopyWith<$Res> {
  factory $PeriodComparisonCopyWith(
          PeriodComparison value, $Res Function(PeriodComparison) then) =
      _$PeriodComparisonCopyWithImpl<$Res, PeriodComparison>;
  @useResult
  $Res call(
      {double currentAmount,
      double previousAmount,
      int currentReceiptCount,
      int previousReceiptCount});
}

/// @nodoc
class _$PeriodComparisonCopyWithImpl<$Res, $Val extends PeriodComparison>
    implements $PeriodComparisonCopyWith<$Res> {
  _$PeriodComparisonCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PeriodComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentAmount = null,
    Object? previousAmount = null,
    Object? currentReceiptCount = null,
    Object? previousReceiptCount = null,
  }) {
    return _then(_value.copyWith(
      currentAmount: null == currentAmount
          ? _value.currentAmount
          : currentAmount // ignore: cast_nullable_to_non_nullable
              as double,
      previousAmount: null == previousAmount
          ? _value.previousAmount
          : previousAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currentReceiptCount: null == currentReceiptCount
          ? _value.currentReceiptCount
          : currentReceiptCount // ignore: cast_nullable_to_non_nullable
              as int,
      previousReceiptCount: null == previousReceiptCount
          ? _value.previousReceiptCount
          : previousReceiptCount // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PeriodComparisonImplCopyWith<$Res>
    implements $PeriodComparisonCopyWith<$Res> {
  factory _$$PeriodComparisonImplCopyWith(_$PeriodComparisonImpl value,
          $Res Function(_$PeriodComparisonImpl) then) =
      __$$PeriodComparisonImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double currentAmount,
      double previousAmount,
      int currentReceiptCount,
      int previousReceiptCount});
}

/// @nodoc
class __$$PeriodComparisonImplCopyWithImpl<$Res>
    extends _$PeriodComparisonCopyWithImpl<$Res, _$PeriodComparisonImpl>
    implements _$$PeriodComparisonImplCopyWith<$Res> {
  __$$PeriodComparisonImplCopyWithImpl(_$PeriodComparisonImpl _value,
      $Res Function(_$PeriodComparisonImpl) _then)
      : super(_value, _then);

  /// Create a copy of PeriodComparison
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentAmount = null,
    Object? previousAmount = null,
    Object? currentReceiptCount = null,
    Object? previousReceiptCount = null,
  }) {
    return _then(_$PeriodComparisonImpl(
      currentAmount: null == currentAmount
          ? _value.currentAmount
          : currentAmount // ignore: cast_nullable_to_non_nullable
              as double,
      previousAmount: null == previousAmount
          ? _value.previousAmount
          : previousAmount // ignore: cast_nullable_to_non_nullable
              as double,
      currentReceiptCount: null == currentReceiptCount
          ? _value.currentReceiptCount
          : currentReceiptCount // ignore: cast_nullable_to_non_nullable
              as int,
      previousReceiptCount: null == previousReceiptCount
          ? _value.previousReceiptCount
          : previousReceiptCount // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PeriodComparisonImpl implements _PeriodComparison {
  const _$PeriodComparisonImpl(
      {required this.currentAmount,
      required this.previousAmount,
      required this.currentReceiptCount,
      required this.previousReceiptCount});

  factory _$PeriodComparisonImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeriodComparisonImplFromJson(json);

  @override
  final double currentAmount;
  @override
  final double previousAmount;
  @override
  final int currentReceiptCount;
  @override
  final int previousReceiptCount;

  @override
  String toString() {
    return 'PeriodComparison(currentAmount: $currentAmount, previousAmount: $previousAmount, currentReceiptCount: $currentReceiptCount, previousReceiptCount: $previousReceiptCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeriodComparisonImpl &&
            (identical(other.currentAmount, currentAmount) ||
                other.currentAmount == currentAmount) &&
            (identical(other.previousAmount, previousAmount) ||
                other.previousAmount == previousAmount) &&
            (identical(other.currentReceiptCount, currentReceiptCount) ||
                other.currentReceiptCount == currentReceiptCount) &&
            (identical(other.previousReceiptCount, previousReceiptCount) ||
                other.previousReceiptCount == previousReceiptCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, currentAmount, previousAmount,
      currentReceiptCount, previousReceiptCount);

  /// Create a copy of PeriodComparison
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeriodComparisonImplCopyWith<_$PeriodComparisonImpl> get copyWith =>
      __$$PeriodComparisonImplCopyWithImpl<_$PeriodComparisonImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeriodComparisonImplToJson(
      this,
    );
  }
}

abstract class _PeriodComparison implements PeriodComparison {
  const factory _PeriodComparison(
      {required final double currentAmount,
      required final double previousAmount,
      required final int currentReceiptCount,
      required final int previousReceiptCount}) = _$PeriodComparisonImpl;

  factory _PeriodComparison.fromJson(Map<String, dynamic> json) =
      _$PeriodComparisonImpl.fromJson;

  @override
  double get currentAmount;
  @override
  double get previousAmount;
  @override
  int get currentReceiptCount;
  @override
  int get previousReceiptCount;

  /// Create a copy of PeriodComparison
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeriodComparisonImplCopyWith<_$PeriodComparisonImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalyticsPeriodData _$AnalyticsPeriodDataFromJson(Map<String, dynamic> json) {
  return _AnalyticsPeriodData.fromJson(json);
}

/// @nodoc
mixin _$AnalyticsPeriodData {
  AnalyticsPeriod get period => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  int get totalReceipts => throw _privateConstructorUsedError;
  double get avgReceiptAmount => throw _privateConstructorUsedError;
  List<TrendPoint> get trendPoints => throw _privateConstructorUsedError;
  PeriodComparison? get comparison => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;

  /// Serializes this AnalyticsPeriodData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalyticsPeriodDataCopyWith<AnalyticsPeriodData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsPeriodDataCopyWith<$Res> {
  factory $AnalyticsPeriodDataCopyWith(
          AnalyticsPeriodData value, $Res Function(AnalyticsPeriodData) then) =
      _$AnalyticsPeriodDataCopyWithImpl<$Res, AnalyticsPeriodData>;
  @useResult
  $Res call(
      {AnalyticsPeriod period,
      double totalAmount,
      int totalReceipts,
      double avgReceiptAmount,
      List<TrendPoint> trendPoints,
      PeriodComparison? comparison,
      DateTime startDate,
      DateTime endDate});

  $PeriodComparisonCopyWith<$Res>? get comparison;
}

/// @nodoc
class _$AnalyticsPeriodDataCopyWithImpl<$Res, $Val extends AnalyticsPeriodData>
    implements $AnalyticsPeriodDataCopyWith<$Res> {
  _$AnalyticsPeriodDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? period = null,
    Object? totalAmount = null,
    Object? totalReceipts = null,
    Object? avgReceiptAmount = null,
    Object? trendPoints = null,
    Object? comparison = freezed,
    Object? startDate = null,
    Object? endDate = null,
  }) {
    return _then(_value.copyWith(
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as AnalyticsPeriod,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      totalReceipts: null == totalReceipts
          ? _value.totalReceipts
          : totalReceipts // ignore: cast_nullable_to_non_nullable
              as int,
      avgReceiptAmount: null == avgReceiptAmount
          ? _value.avgReceiptAmount
          : avgReceiptAmount // ignore: cast_nullable_to_non_nullable
              as double,
      trendPoints: null == trendPoints
          ? _value.trendPoints
          : trendPoints // ignore: cast_nullable_to_non_nullable
              as List<TrendPoint>,
      comparison: freezed == comparison
          ? _value.comparison
          : comparison // ignore: cast_nullable_to_non_nullable
              as PeriodComparison?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PeriodComparisonCopyWith<$Res>? get comparison {
    if (_value.comparison == null) {
      return null;
    }

    return $PeriodComparisonCopyWith<$Res>(_value.comparison!, (value) {
      return _then(_value.copyWith(comparison: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalyticsPeriodDataImplCopyWith<$Res>
    implements $AnalyticsPeriodDataCopyWith<$Res> {
  factory _$$AnalyticsPeriodDataImplCopyWith(_$AnalyticsPeriodDataImpl value,
          $Res Function(_$AnalyticsPeriodDataImpl) then) =
      __$$AnalyticsPeriodDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AnalyticsPeriod period,
      double totalAmount,
      int totalReceipts,
      double avgReceiptAmount,
      List<TrendPoint> trendPoints,
      PeriodComparison? comparison,
      DateTime startDate,
      DateTime endDate});

  @override
  $PeriodComparisonCopyWith<$Res>? get comparison;
}

/// @nodoc
class __$$AnalyticsPeriodDataImplCopyWithImpl<$Res>
    extends _$AnalyticsPeriodDataCopyWithImpl<$Res, _$AnalyticsPeriodDataImpl>
    implements _$$AnalyticsPeriodDataImplCopyWith<$Res> {
  __$$AnalyticsPeriodDataImplCopyWithImpl(_$AnalyticsPeriodDataImpl _value,
      $Res Function(_$AnalyticsPeriodDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? period = null,
    Object? totalAmount = null,
    Object? totalReceipts = null,
    Object? avgReceiptAmount = null,
    Object? trendPoints = null,
    Object? comparison = freezed,
    Object? startDate = null,
    Object? endDate = null,
  }) {
    return _then(_$AnalyticsPeriodDataImpl(
      period: null == period
          ? _value.period
          : period // ignore: cast_nullable_to_non_nullable
              as AnalyticsPeriod,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      totalReceipts: null == totalReceipts
          ? _value.totalReceipts
          : totalReceipts // ignore: cast_nullable_to_non_nullable
              as int,
      avgReceiptAmount: null == avgReceiptAmount
          ? _value.avgReceiptAmount
          : avgReceiptAmount // ignore: cast_nullable_to_non_nullable
              as double,
      trendPoints: null == trendPoints
          ? _value._trendPoints
          : trendPoints // ignore: cast_nullable_to_non_nullable
              as List<TrendPoint>,
      comparison: freezed == comparison
          ? _value.comparison
          : comparison // ignore: cast_nullable_to_non_nullable
              as PeriodComparison?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalyticsPeriodDataImpl implements _AnalyticsPeriodData {
  const _$AnalyticsPeriodDataImpl(
      {required this.period,
      required this.totalAmount,
      required this.totalReceipts,
      required this.avgReceiptAmount,
      required final List<TrendPoint> trendPoints,
      required this.comparison,
      required this.startDate,
      required this.endDate})
      : _trendPoints = trendPoints;

  factory _$AnalyticsPeriodDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalyticsPeriodDataImplFromJson(json);

  @override
  final AnalyticsPeriod period;
  @override
  final double totalAmount;
  @override
  final int totalReceipts;
  @override
  final double avgReceiptAmount;
  final List<TrendPoint> _trendPoints;
  @override
  List<TrendPoint> get trendPoints {
    if (_trendPoints is EqualUnmodifiableListView) return _trendPoints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trendPoints);
  }

  @override
  final PeriodComparison? comparison;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;

  @override
  String toString() {
    return 'AnalyticsPeriodData(period: $period, totalAmount: $totalAmount, totalReceipts: $totalReceipts, avgReceiptAmount: $avgReceiptAmount, trendPoints: $trendPoints, comparison: $comparison, startDate: $startDate, endDate: $endDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsPeriodDataImpl &&
            (identical(other.period, period) || other.period == period) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.totalReceipts, totalReceipts) ||
                other.totalReceipts == totalReceipts) &&
            (identical(other.avgReceiptAmount, avgReceiptAmount) ||
                other.avgReceiptAmount == avgReceiptAmount) &&
            const DeepCollectionEquality()
                .equals(other._trendPoints, _trendPoints) &&
            (identical(other.comparison, comparison) ||
                other.comparison == comparison) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      period,
      totalAmount,
      totalReceipts,
      avgReceiptAmount,
      const DeepCollectionEquality().hash(_trendPoints),
      comparison,
      startDate,
      endDate);

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsPeriodDataImplCopyWith<_$AnalyticsPeriodDataImpl> get copyWith =>
      __$$AnalyticsPeriodDataImplCopyWithImpl<_$AnalyticsPeriodDataImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalyticsPeriodDataImplToJson(
      this,
    );
  }
}

abstract class _AnalyticsPeriodData implements AnalyticsPeriodData {
  const factory _AnalyticsPeriodData(
      {required final AnalyticsPeriod period,
      required final double totalAmount,
      required final int totalReceipts,
      required final double avgReceiptAmount,
      required final List<TrendPoint> trendPoints,
      required final PeriodComparison? comparison,
      required final DateTime startDate,
      required final DateTime endDate}) = _$AnalyticsPeriodDataImpl;

  factory _AnalyticsPeriodData.fromJson(Map<String, dynamic> json) =
      _$AnalyticsPeriodDataImpl.fromJson;

  @override
  AnalyticsPeriod get period;
  @override
  double get totalAmount;
  @override
  int get totalReceipts;
  @override
  double get avgReceiptAmount;
  @override
  List<TrendPoint> get trendPoints;
  @override
  PeriodComparison? get comparison;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;

  /// Create a copy of AnalyticsPeriodData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalyticsPeriodDataImplCopyWith<_$AnalyticsPeriodDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
