import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/data/vision_ocr_engine.dart';
import 'package:ticket_app/features/scan/domain/entities/ocr_result.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';

import '../../prostore_ocr_fixture.dart';
import '../../scan_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('захват → ревью позиций → сохранение', (tester) async {
    await pumpApp(
      tester,
      const ScanScreen(),
      overrides: [
        photoPickerProvider
            .overrideWithValue(FakePhotoPicker()..result = kValidPngBytes),
        receiptOcrEngineProvider.overrideWithValue(
            FakeOcrEngine(const OcrResult(lines: prostoreOcrLines, qr: 'УИ'))),
        scanRepositoryProvider.overrideWithValue(FakeScanRepository()),
      ],
    );

    expect(find.text('Из галереи'), findsOneWidget);
    await tester.tap(find.text('Из галереи'));
    await tester.pumpAndSettle();

    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Сканировать ещё'), findsOneWidget);
  });
}
