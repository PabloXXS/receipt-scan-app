import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_app/features/scan/data/image_compressor.dart';

void main() {
  test('ресайзит длинную сторону до 1600 и отдаёт JPEG', () {
    final big = img.Image(width: 3200, height: 1600);
    final input = img.encodePng(big);

    final out = compressReceiptImage(input);

    // JPEG-сигнатура (SOI): FF D8.
    expect(out[0], 0xFF);
    expect(out[1], 0xD8);
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, 1600);
    expect(decoded.height, 800);
  });

  test('не увеличивает мелкое изображение', () {
    final small = img.Image(width: 800, height: 600);
    final decoded =
        img.decodeImage(compressReceiptImage(img.encodePng(small)))!;
    expect(decoded.width, 800);
    expect(decoded.height, 600);
  });

  test('на нераспознаваемых байтах возвращает исходные', () {
    final garbage = img.encodePng(img.Image(width: 1, height: 1)).sublist(0, 4);
    expect(compressReceiptImage(garbage), garbage);
  });
}
