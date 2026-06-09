/// Назначение: сценарий создания чека из фотографии.
///
/// Слой: domain
/// Фича: scan
/// Зависимости: dart:typed_data, domain/repositories/scan_repository.dart.
/// Ключевые типы: CreateReceiptFromPhoto.
library;

import 'dart:typed_data';

import '../repositories/scan_repository.dart';

/// Создаёт чек из байтов фотографии. Возвращает id чека.
class CreateReceiptFromPhoto {
  const CreateReceiptFromPhoto(this._repo);
  final ScanRepository _repo;

  Future<String> call(Uint8List photoBytes) =>
      _repo.createReceiptFromPhoto(photoBytes);
}
