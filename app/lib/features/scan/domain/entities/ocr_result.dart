/// Назначение: результат OCR чека — упорядоченные строки текста и QR.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: нет.
/// Ключевые типы: OcrResult.
library;

/// Результат распознавания: строки сверху вниз и (опц.) полезная нагрузка QR.
class OcrResult {
  const OcrResult({required this.lines, this.qr});

  /// Строки текста в порядке сверху вниз.
  final List<String> lines;

  /// Содержимое QR (УИ), если найден.
  final String? qr;
}
