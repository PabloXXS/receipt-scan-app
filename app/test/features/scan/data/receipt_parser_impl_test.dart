import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/data/receipt_parser_impl.dart';

import '../prostore_ocr_fixture.dart';

void main() {
  final parser = ReceiptParserImpl();

  test('извлекает 14 позиций чека ProStore', () {
    final d =
        parser.parse(const OcrResult(lines: prostoreOcrLines, qr: '2B08...'));
    expect(d.items.length, 14);
  });

  test('сумма позиций сходится с итогом 65.89', () {
    final d = parser.parse(const OcrResult(lines: prostoreOcrLines));
    expect(d.total, 65.89);
    expect(d.itemsSum, closeTo(65.89, 0.01));
    expect(d.totalMatches, isTrue);
  });

  test('склеивает многострочные названия и парсит вес', () {
    final d = parser.parse(const OcrResult(lines: prostoreOcrLines));
    expect(d.items.first.rawName,
        'Напиток Coca-Cola без сахара безалк газ 2л ПЭТ');
    final weighted = d.items.firstWhere((i) => i.rawName.startsWith('Рулет'));
    expect(weighted.qty, closeTo(0.562, 0.0001));
    expect(weighted.unitPrice, 15.77);
    expect(weighted.sum, 8.86);
  });

  test('парсит дату и пробрасывает qr', () {
    final d =
        parser.parse(const OcrResult(lines: prostoreOcrLines, qr: 'УИ-X'));
    expect(d.purchasedAt, DateTime(2026, 6, 10, 14, 8, 18));
    expect(d.qrRaw, 'УИ-X');
  });

  test('пустой ввод → нет позиций', () {
    final d = parser.parse(const OcrResult(lines: []));
    expect(d.items, isEmpty);
    expect(d.total, isNull);
  });
}
