import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/data/receipt_parser_impl.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';

import '../prostore_vision_real.dart';

void main() {
  final parser = ReceiptParserImpl();

  test('реальный вывод Vision: извлекает все 14 позиций, сумма 65.89', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    expect(d.items.length, 14);
    expect(d.itemsSum, closeTo(65.89, 0.01));
  });

  test('весовая позиция: сумма вычислена из unit×qty, когда OCR её не дал', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    final rulet = d.items.firstWhere((i) => i.rawName.startsWith('Рулет'));
    expect(rulet.qty, closeTo(0.562, 0.0001));
    expect(rulet.unitPrice, 15.77);
    expect(rulet.sum, closeTo(8.86, 0.01));
  });

  test('[M]→ЕМ] не ломает заголовок: «Сыр» — отдельная позиция', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    final cheese = d.items.where((i) => i.rawName.contains('Сыр плав'));
    expect(cheese.length, 1);
    expect(cheese.first.sum, 5.99);
  });

  test('разделитель # и составная строка цены парсятся (Фарш)', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    final farsh =
        d.items.firstWhere((i) => i.rawName.toLowerCase().contains('фарш'));
    expect(farsh.qty, closeTo(0.488, 0.0001));
    expect(farsh.sum, 10.73);
  });

  test('цена, разбитая на строки (сумма отдельно): первая позиция', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    expect(d.items.first.unitPrice, 5.49);
    expect(d.items.first.sum, 5.49);
  });

  test('нет строки ИТОГО в кадре → total null', () {
    final d = parser.parse(const OcrResult(lines: prostoreVisionRealLines));
    expect(d.total, isNull);
  });
}
