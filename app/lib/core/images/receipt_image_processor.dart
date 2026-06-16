/// Назначение: подготовка фото чека к загрузке (даунскейл по большей стороне, JPEG).
///
/// Слой: core/images
/// Зависимости: dart:typed_data, package:image.
/// Ключевые типы: processReceiptPhoto, kReceiptPhotoMaxSide.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Максимальная сторона фото чека в пикселях.
const int kReceiptPhotoMaxSide = 1600;

/// Декодирует [input], ужимает по большей стороне до [kReceiptPhotoMaxSide]
/// с сохранением пропорций (если больше) и кодирует в JPEG (q=80).
/// Бросает [FormatException], если [input] — не изображение.
Uint8List processReceiptPhoto(Uint8List input) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    // Некоторые декодеры package:image бросают RangeError на мусорных байтах.
    decoded = null;
  }
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать изображение');
  }
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longest > kReceiptPhotoMaxSide
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? kReceiptPhotoMaxSide : null,
          height: decoded.height > decoded.width ? kReceiptPhotoMaxSide : null,
        )
      : decoded;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
}
