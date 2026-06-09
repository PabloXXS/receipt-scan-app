import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';

import '../../scan_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('захват → превью → отправка → успех', (tester) async {
    final picker = FakePhotoPicker()..result = kValidPngBytes;
    final repo = FakeScanRepository();

    await pumpApp(
      tester,
      const ScanScreen(),
      overrides: [
        photoPickerProvider.overrideWithValue(picker),
        scanRepositoryProvider.overrideWithValue(repo),
      ],
    );

    // Экран захвата.
    expect(find.text('Сфотографировать'), findsOneWidget);
    expect(find.text('Из галереи'), findsOneWidget);

    // Выбор фото → превью.
    await tester.tap(find.text('Сфотографировать'));
    await tester.pumpAndSettle();
    expect(find.text('Отправить'), findsOneWidget);
    expect(find.text('Переснять'), findsOneWidget);

    // Отправка → успех.
    await tester.tap(find.text('Отправить'));
    await tester.pumpAndSettle();
    expect(find.text('Сканировать ещё'), findsOneWidget);
  });
}
