/// Назначение: провайдеры деталей чека и signed URL фото чека.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: riverpod_annotation, data/repositories/receipts_repository_impl.dart,
///   domain/entities/receipt_details.dart.
/// Ключевые типы: receiptDetailsProvider, receiptPhotoUrlProvider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/receipts_repository_impl.dart';
import '../../domain/entities/receipt_details.dart';

part 'receipt_details_controller.g.dart';

/// Детали чека по id.
@riverpod
// ignore: deprecated_member_use_from_same_package
Future<ReceiptDetails> receiptDetails(ReceiptDetailsRef ref, String id) {
  return ref.watch(receiptsRepositoryProvider).getById(id);
}

/// Signed URL фото по пути в бакете; null — если фото нет/ошибка.
@riverpod
// ignore: deprecated_member_use_from_same_package
Future<String?> receiptPhotoUrl(ReceiptPhotoUrlRef ref, String path) {
  return ref.watch(receiptsRepositoryProvider).photoUrl(path);
}
