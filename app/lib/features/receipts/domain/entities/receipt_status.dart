/// Назначение: статус обработки чека (значения колонки `receipts.status`).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: нет.
/// Ключевые типы: ReceiptStatus.
library;

/// Статус чека в пайплайне обработки.
enum ReceiptStatus {
  /// В очереди на обработку.
  pending('В очереди'),

  /// Обрабатывается воркером.
  processing('Обработка'),

  /// Обработан успешно.
  done('Готово'),

  /// Обработка завершилась ошибкой.
  failed('Ошибка');

  const ReceiptStatus(this.label);

  /// Человекочитаемая подпись для бейджа.
  final String label;

  /// Маппинг из значения колонки `receipts.status`. Неизвестное → [pending].
  static ReceiptStatus fromDb(String? value) => switch (value) {
        'processing' => ReceiptStatus.processing,
        'done' => ReceiptStatus.done,
        'failed' => ReceiptStatus.failed,
        _ => ReceiptStatus.pending,
      };
}
