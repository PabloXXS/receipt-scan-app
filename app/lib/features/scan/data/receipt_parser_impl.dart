/// Назначение: эвристический парсер строк OCR в ReceiptDraft (формат РБ/ProStore).
///
/// Слой: data
/// Фича: scan
/// Зависимости: domain/entities/*, domain/ocr/receipt_parser.dart.
/// Ключевые типы: ReceiptParserImpl.
library;

import '../domain/entities/ocr_result.dart';
import '../domain/entities/receipt_draft.dart';
import '../domain/ocr/receipt_parser.dart';

/// Парсер кассовых чеков: строка-цена «<цена> *<кол-во> <итог>» завершает позицию,
/// строка «<код> <название>» начинает её, прочие строки — продолжение названия.
class ReceiptParserImpl implements ReceiptParser {
  static final _price =
      RegExp(r'(\d+[.,]\d{2})\s*\*\s*(\d+[.,]\d{1,3})\s+(\d+[.,]\d{2})');
  static final _header = RegExp(r'^(?:\[[МM]\]\s*)?\d{6,}\s+(.+)$');
  static final _total =
      RegExp(r'ИТОГО\s+К\s+ОПЛАТЕ\D*(\d+[.,]\d{2})', caseSensitive: false);
  static final _dt =
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');

  double _num(String s) => double.parse(s.replaceAll(',', '.'));

  @override
  ReceiptDraft parse(OcrResult ocr) {
    final items = <ReceiptItemDraft>[];
    String? name;
    double? total;
    DateTime? purchasedAt;

    for (final raw in ocr.lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final price = _price.firstMatch(line);
      if (price != null && name != null) {
        items.add(ReceiptItemDraft(
          rawName: name.trim(),
          unitPrice: _num(price.group(1)!),
          qty: _num(price.group(2)!),
          sum: _num(price.group(3)!),
        ));
        name = null;
        continue;
      }

      final tot = _total.firstMatch(line);
      if (tot != null) {
        total = _num(tot.group(1)!);
        name = null;
        continue;
      }

      final dt = _dt.firstMatch(line);
      if (dt != null) {
        purchasedAt = DateTime(
          int.parse(dt.group(3)!),
          int.parse(dt.group(2)!),
          int.parse(dt.group(1)!),
          int.parse(dt.group(4)!),
          int.parse(dt.group(5)!),
          int.parse(dt.group(6)!),
        );
        continue;
      }

      final head = _header.firstMatch(line);
      if (head != null) {
        name = head.group(1)!;
        continue;
      }

      if (name != null) name = '$name $line';
    }

    return ReceiptDraft(
      items: items,
      total: total,
      purchasedAt: purchasedAt,
      qrRaw: ocr.qr,
    );
  }
}
