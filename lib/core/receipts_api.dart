import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ReceiptLine {
  ReceiptLine({
    required this.name,
    required this.qty,
    required this.price,
  });

  final String name;
  final double qty;
  final double price;
}

class ReceiptsApi {
  ReceiptsApi();
  String get _base => SupabaseConfig.projectUrl;

  Map<String, String> get _headers => <String, String>{
        'Authorization':
            'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
        'apikey': SupabaseConfig.anonKey,
        'Content-Type': 'application/json',
      };

  // Deprecated: используйте ReceiptsRepository вместо этого метода
  // Оставлен для обратной совместимости
  Future<List<Map<String, dynamic>>> fetchReceipts({int limit = 50}) async {
    // Используем новое поле merchant_name вместо merchant_id
    // Сортировка: сначала purchase_date/time (если есть), затем created_at
    final Uri url = Uri.parse(
        '$_base/rest/v1/receipts?select=id,created_at,total,purchase_date,purchase_time,merchant_name,store_confidence&order=purchase_date.desc,purchase_time.desc,created_at.desc&limit=$limit');
    final http.Response res = await http.get(url, headers: _headers);
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final List<dynamic> data = json.decode(res.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<ReceiptLine>> fetchReceiptItems(
      {required String receiptId}) async {
    final Uri url = Uri.parse(
        '$_base/rest/v1/receipt_items?select=name,qty,price&receipt_id=eq.$receiptId&order=name.asc');
    final http.Response res = await http.get(url, headers: _headers);
    if (res.statusCode >= 400) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final List<dynamic> data = json.decode(res.body) as List<dynamic>;
    return data.map((dynamic row) {
      final Map<String, dynamic> m = row as Map<String, dynamic>;
      final String name = (m['name'] as String?) ?? '';
      final double qty = (m['qty'] as num?)?.toDouble() ?? 1;
      final double price = (m['price'] as num?)?.toDouble() ?? 0;
      return ReceiptLine(name: name, qty: qty, price: price);
    }).toList();
  }

  Future<String> analyzeByUrl({required String url}) async {
    final SupabaseClient client = Supabase.instance.client;
    final dynamic resp = await client.functions.invoke(
      'analyze',
      body: <String, dynamic>{'url': url},
    );
    final int status = (resp.status as int?) ?? 200;
    if (status >= 400) {
      throw Exception('analyze error: HTTP $status ${resp.data}');
    }
    final Map<String, dynamic> body =
        (resp.data as Map).cast<String, dynamic>();
    final String receiptId = body['receipt_id'] as String;
    return receiptId;
  }
}
