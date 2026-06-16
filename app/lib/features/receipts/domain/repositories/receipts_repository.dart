/// Назначение: контракт доступа к чекам (список, детали, удаление, фото).
///
/// Слой: domain
/// Фича: receipts
/// Зависимости: domain/entities (receipt.dart, receipt_details.dart).
/// Ключевые типы: ReceiptsRepository.
library;

import '../entities/receipt.dart';
import '../entities/receipt_details.dart';

/// Сценарии работы со списком и деталями чеков. Реализация — в слое data.
abstract interface class ReceiptsRepository {
  /// Страница чеков, отсортированных по `created_at desc`.
  Future<List<Receipt>> list({required int limit, required int offset});

  /// Детали чека с позициями.
  Future<ReceiptDetails> getById(String id);

  /// Удаляет чек владельца.
  Future<void> delete(String id);

  /// Signed URL фото чека из приватного бакета; null — если фото нет.
  Future<String?> photoUrl(String path);
}
