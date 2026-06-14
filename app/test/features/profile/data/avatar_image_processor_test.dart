import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ticket_app/features/profile/data/avatar_image_processor.dart';

void main() {
  test('кропит до квадрата и ужимает до <= 512px', () {
    // Прямоугольник 800x400.
    final src = img.Image(width: 800, height: 400);
    final bytes = img.encodeJpg(src);

    final out = processAvatar(bytes);
    final decoded = img.decodeImage(out)!;

    expect(decoded.width, decoded.height); // квадрат
    expect(decoded.width, lessThanOrEqualTo(512));
  });
}
