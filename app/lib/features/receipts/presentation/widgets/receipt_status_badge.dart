/// Назначение: бейдж статуса чека (маппинг ReceiptStatus → AppBadge).
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, shared/components (AppBadge),
///   domain/entities/receipt_status.dart.
/// Ключевые типы: ReceiptStatusBadge.
library;

import 'package:flutter/material.dart';

import '../../../../shared/components/components.dart';
import '../../domain/entities/receipt_status.dart';

/// Бейдж со статусом чека и соответствующей тональностью.
class ReceiptStatusBadge extends StatelessWidget {
  const ReceiptStatusBadge({required this.status, super.key});

  final ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      ReceiptStatus.pending => AppBadgeTone.neutral,
      ReceiptStatus.processing => AppBadgeTone.warning,
      ReceiptStatus.done => AppBadgeTone.success,
      ReceiptStatus.failed => AppBadgeTone.error,
    };
    return AppBadge(label: status.label, tone: tone);
  }
}
