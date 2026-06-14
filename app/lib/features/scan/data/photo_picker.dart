/// Назначение: выбор фото чека из галереи (обёртка над image_picker).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, flutter_riverpod, image_picker.
/// Ключевые типы: PhotoPicker, ImagePickerPhotoPicker, photoPickerProvider.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Абстракция выбора фото из галереи. `null` — пользователь отменил выбор.
/// (Камера в приложении — через LiveCameraScreen, не через image_picker.)
abstract interface class PhotoPicker {
  Future<Uint8List?> pickFromGallery();
}

/// Реализация поверх image_picker. Сжатие делаем сами (imageQuality: 100).
class ImagePickerPhotoPicker implements PhotoPicker {
  ImagePickerPhotoPicker([ImagePicker? picker])
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<Uint8List?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 100);
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<Uint8List?> pickFromGallery() => _pick(ImageSource.gallery);
}

/// DI-провайдер выбора фото.
final photoPickerProvider =
    Provider<PhotoPicker>((ref) => ImagePickerPhotoPicker());
