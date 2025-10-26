import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/receipt.dart';
import '../models/receipt_item.dart';

part 'receipts_repository.g.dart';

@riverpod
ReceiptsRepository receiptsRepository(ReceiptsRepositoryRef ref) {
  return ReceiptsRepository();
}

class ReceiptsRepository {
  DateTime? _parseTime(String? timeString) {
    if (timeString == null) return null;
    try {
      // Время приходит как "HH:MM:SS", преобразуем в DateTime
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return DateTime(1970, 1, 1, int.parse(parts[0]), int.parse(parts[1]),
            parts.length > 2 ? int.parse(parts[2].split('.')[0]) : 0);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  Future<List<Receipt>> getAllReceipts() async {
    final client = Supabase.instance.client;

    final response = await client
        .from('receipts')
        .select()
        .eq('is_deleted', false)
        .eq('status', 'ready') // Показываем только готовые чеки
        .order('purchase_date', ascending: false)
        .order('purchase_time', ascending: false)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((json) {
      final data = Map<String, dynamic>.from(json as Map<String, dynamic>);
      // Преобразуем purchase_time из строки в DateTime
      if (data['purchase_time'] != null) {
        data['purchase_time'] =
            _parseTime(data['purchase_time'] as String?)?.toIso8601String();
      }
      return Receipt.fromJson(data);
    }).toList();
  }

  Future<Receipt> getReceiptById(String id) async {
    final client = Supabase.instance.client;

    final response = await client
        .from('receipts')
        .select()
        .eq('id', id)
        .eq('is_deleted', false)
        .single();

    final data = Map<String, dynamic>.from(response as Map<String, dynamic>);
    // Преобразуем purchase_time из строки в DateTime
    if (data['purchase_time'] != null) {
      data['purchase_time'] =
          _parseTime(data['purchase_time'] as String?)?.toIso8601String();
    }
    return Receipt.fromJson(data);
  }

  Future<List<ReceiptItem>> getReceiptItems(String receiptId) async {
    final client = Supabase.instance.client;

    final response = await client
        .from('receipt_items')
        .select('*, categories(id, name)')
        .eq('receipt_id', receiptId)
        .eq('is_deleted', false);

    return (response as List<dynamic>).map((json) {
      final category = json['categories'] as Map<String, dynamic>?;
      return ReceiptItem(
        id: json['id'] as String,
        receiptId: json['receipt_id'] as String,
        name: json['name'] as String,
        quantity: (json['qty'] as num).toDouble(),
        price: (json['price'] as num).toDouble(),
        categoryId: json['category_id'] as String?,
        categoryName: category?['name'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
    }).toList();
  }
}
