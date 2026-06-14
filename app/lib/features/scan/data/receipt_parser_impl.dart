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

/// Парсер кассовых чеков, устойчивый к реальному выводу Vision.
///
/// Модель: позиция = блок от строки-заголовка «<код 6+ цифр> <название>» до
/// следующего заголовка (или строки ИТОГО). Внутри блока строки цены могут быть
/// дроблёными и искажёнными: разделитель `* # · x х`, десятичные `.`/`,`, сумма
/// иногда на отдельной строке или отсутствует (тогда считаем `unit×qty`).
class ReceiptParserImpl implements ReceiptParser {
  // Заголовок: до 5 нецифровых символов (мусор вида «ЕМ] »), затем код и название.
  static final _header = RegExp(r'^[^\d]{0,5}(\d{6,})\s+(\D.*)$');
  // «unit <разд> qty [sum]» — разделитель и десятичные в разных начертаниях.
  static final _price = RegExp(
    r'(\d+[.,]\d{1,3})\s*[*#·xх]\s*(\d+[.,]\d{1,3})(?:\s+(\d+[.,]\d{2}))?',
  );
  // Одиночная денежная сумма на строке.
  static final _amount = RegExp(r'^\s*(\d+[.,]\d{2})\s*$');
  static final _total = RegExp(r'ИТОГО.*?(\d+[.,]\d{2})', caseSensitive: false);
  static final _dt =
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');
  static final _letter = RegExp(r'[A-Za-zА-Яа-яЁё]');

  double _num(String s) => double.parse(s.replaceAll(',', '.'));
  double _round2(double v) => double.parse(v.toStringAsFixed(2));

  @override
  ReceiptDraft parse(OcrResult ocr) {
    final lines =
        ocr.lines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Граница зоны позиций — строка ИТОГО (если есть).
    var bound = lines.length;
    for (var i = 0; i < lines.length; i++) {
      if (_total.hasMatch(lines[i])) {
        bound = i;
        break;
      }
    }

    // Индексы заголовков позиций в пределах зоны позиций.
    final headers = <int>[];
    for (var i = 0; i < bound; i++) {
      if (_header.hasMatch(lines[i])) headers.add(i);
    }

    final items = <ReceiptItemDraft>[];
    for (var h = 0; h < headers.length; h++) {
      final start = headers[h];
      final end = h + 1 < headers.length ? headers[h + 1] : bound;
      final item = _parseBlock(lines.sublist(start, end));
      if (item != null) items.add(item);
    }

    double? total;
    DateTime? purchasedAt;
    for (final l in lines) {
      final tm = _total.firstMatch(l);
      if (tm != null) total = _num(tm.group(1)!);
      final dm = _dt.firstMatch(l);
      if (dm != null) {
        purchasedAt = DateTime(
          int.parse(dm.group(3)!),
          int.parse(dm.group(2)!),
          int.parse(dm.group(1)!),
          int.parse(dm.group(4)!),
          int.parse(dm.group(5)!),
          int.parse(dm.group(6)!),
        );
      }
    }

    return ReceiptDraft(
      items: items,
      total: total,
      purchasedAt: purchasedAt,
      qrRaw: ocr.qr,
    );
  }

  /// Разбирает блок строк одной позиции (первая строка — заголовок).
  ReceiptItemDraft? _parseBlock(List<String> block) {
    final head = _header.firstMatch(block.first);
    if (head == null) return null;
    var name = head.group(2)!.trim();

    double? unit, qty, sum;
    for (var i = 1; i < block.length; i++) {
      final line = block[i];
      final p = _price.firstMatch(line);
      if (p != null) {
        unit = _num(p.group(1)!);
        qty = _num(p.group(2)!);
        if (p.group(3) != null) sum = _num(p.group(3)!);
        continue;
      }
      final a = _amount.firstMatch(line);
      if (a != null) {
        sum ??= _num(a.group(1)!);
        continue;
      }
      // Продолжение названия — только содержательные (с буквами) строки;
      // числовые «обрывки» OCR в название не тянем.
      if (_letter.hasMatch(line)) name = '$name $line';
    }

    if (unit == null && qty == null && sum == null) return null;
    qty ??= 1;
    unit ??= sum;
    sum ??= unit != null ? _round2(unit * qty) : null;
    if (sum == null) return null;

    return ReceiptItemDraft(
      rawName: name.trim(),
      qty: qty,
      unitPrice: unit ?? sum,
      sum: sum,
    );
  }
}
