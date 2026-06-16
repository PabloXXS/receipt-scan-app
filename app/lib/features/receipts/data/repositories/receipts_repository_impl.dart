/// Назначение: реализация ReceiptsRepository поверх remote datasource.
///
/// Слой: data
/// Фича: receipts
/// Зависимости: flutter_riverpod, datasources/receipts_remote_datasource.dart,
///   receipts_error_mapper.dart, domain/repositories/receipts_repository.dart.
/// Ключевые типы: ReceiptsRepositoryImpl, receiptsRepositoryProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/entities/receipt_details.dart';
import '../../domain/repositories/receipts_repository.dart';
import '../datasources/receipts_remote_datasource.dart';
import '../receipts_error_mapper.dart';

/// Делегирует datasource, оборачивает исключения в ReceiptsFailure.
class ReceiptsRepositoryImpl implements ReceiptsRepository {
  const ReceiptsRepositoryImpl(this._ds);

  final ReceiptsRemoteDataSource _ds;

  @override
  Future<List<Receipt>> list({required int limit, required int offset}) async {
    try {
      return await _ds.fetchPage(limit: limit, offset: offset);
    } catch (e) {
      throw mapReceiptsException(e);
    }
  }

  @override
  Future<ReceiptDetails> getById(String id) async {
    try {
      return await _ds.fetchById(id);
    } catch (e) {
      throw mapReceiptsException(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _ds.deleteById(id);
    } catch (e) {
      throw const ReceiptsDeleteFailure();
    }
  }

  @override
  Future<String?> photoUrl(String path) async {
    try {
      return await _ds.createPhotoUrl(path);
    } catch (_) {
      return null; // отсутствие фото не должно ломать список
    }
  }
}

/// DI-провайдер репозитория чеков.
final receiptsRepositoryProvider = Provider<ReceiptsRepository>(
  (ref) => ReceiptsRepositoryImpl(ref.watch(receiptsRemoteDataSourceProvider)),
);
