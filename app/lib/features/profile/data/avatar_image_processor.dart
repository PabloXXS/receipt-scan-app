/// Назначение: подготовка изображения аватара (центр-кроп в квадрат, даунскейл, JPEG).
///
/// Слой: data
/// Фича: profile
/// Зависимости: dart:typed_data, package:image.
/// Ключевые типы: processAvatar, kAvatarMaxSide.
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Максимальная сторона аватара в пикселях.
const int kAvatarMaxSide = 512;

/// Декодирует [input], делает центр-квадрат-кроп, ужимает до [kAvatarMaxSide]
/// и кодирует в JPEG (q=85). Бросает [FormatException], если не изображение.
Uint8List processAvatar(Uint8List input) {
  final decoded = img.decodeImage(input);
  if (decoded == null) {
    throw const FormatException('Не удалось прочитать изображение');
  }
  final side = decoded.width < decoded.height ? decoded.width : decoded.height;
  final cropped = img.copyCrop(
    decoded,
    x: (decoded.width - side) ~/ 2,
    y: (decoded.height - side) ~/ 2,
    width: side,
    height: side,
  );
  final resized = side > kAvatarMaxSide
      ? img.copyResize(cropped, width: kAvatarMaxSide, height: kAvatarMaxSide)
      : cropped;
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}
