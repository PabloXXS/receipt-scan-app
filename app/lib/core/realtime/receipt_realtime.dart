/// Назначение: Realtime-подписки на строку чека и его позиции.
///
/// Слой: core/infra
/// Зависимости: flutter_riverpod, supabase_flutter, core/supabase/supabase_providers.dart.
/// Ключевые типы: ReceiptRealtime, SupabaseReceiptRealtime, receiptRealtimeProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_providers.dart';

/// Поток обновлений строки `receipts` и её `receipt_items`.
abstract interface class ReceiptRealtime {
  /// Стрим строк `receipts` по id (одна строка или пусто).
  Stream<List<Map<String, dynamic>>> watchReceipt(String id);

  /// Стрим позиций `receipt_items` по receipt_id.
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId);
}

/// Реализация поверх Supabase Realtime (`.stream()`).
class SupabaseReceiptRealtime implements ReceiptRealtime {
  const SupabaseReceiptRealtime(this._client);

  final SupabaseClient _client;

  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) =>
      _client.from('receipts').stream(primaryKey: ['id']).eq('id', id);

  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) => _client
      .from('receipt_items')
      .stream(primaryKey: ['id']).eq('receipt_id', receiptId);
}

/// DI-провайдер Realtime-сервиса чеков.
final receiptRealtimeProvider = Provider<ReceiptRealtime>(
  (ref) => SupabaseReceiptRealtime(ref.watch(supabaseClientProvider)),
);
