import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_app/core/images/receipt_image_processor.dart';

void main() {
  test('валидное изображение → непустой JPEG', () {
    final png =
        Uint8List.fromList(img.encodePng(img.Image(width: 10, height: 20)));
    final out = processReceiptPhoto(png);
    expect(out, isNotEmpty);
    final decoded = img.decodeImage(out);
    expect(decoded, isNotNull);
  });

  test(
      'большое изображение ужимается до kReceiptPhotoMaxSide по большей стороне',
      () {
    final png =
        Uint8List.fromList(img.encodePng(img.Image(width: 4000, height: 2000)));
    final decoded = img.decodeImage(processReceiptPhoto(png))!;
    expect(decoded.width, kReceiptPhotoMaxSide); // 4000 → 1600
    expect(decoded.height, 800); // пропорции сохранены
  });

  test('маленькое изображение не увеличивается', () {
    final png =
        Uint8List.fromList(img.encodePng(img.Image(width: 100, height: 50)));
    final decoded = img.decodeImage(processReceiptPhoto(png))!;
    expect(decoded.width, 100);
    expect(decoded.height, 50);
  });

  test('не-изображение → FormatException', () {
    expect(() => processReceiptPhoto(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<FormatException>()));
  });
}
