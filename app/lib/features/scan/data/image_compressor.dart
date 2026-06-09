/// Назначение: сжатие фото чека перед загрузкой (ресайз + JPEG).
///
/// Слой: data
/// Фича: scan
/// Зависимости: dart:typed_data, package:image.
/// Ключевые типы: compressReceiptImage.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Сжимает фото чека: ресайз длинной стороны до [maxSide] и кодирование в JPEG
/// качества [quality]. Если байты не распознаны как изображение — отдаёт их как есть.
Uint8List compressReceiptImage(
  Uint8List input, {
  int maxSide = 1600,
  int quality = 85,
}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(input);
  } catch (_) {
    return input;
  }
  if (decoded == null) return input;

  final needsResize = decoded.width > maxSide || decoded.height > maxSide;
  final resized = needsResize
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxSide : null,
          height: decoded.height > decoded.width ? maxSide : null,
        )
      : decoded;

  return img.encodeJpg(resized, quality: quality);
}
