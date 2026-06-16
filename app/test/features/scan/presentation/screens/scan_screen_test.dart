import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/realtime/receipt_realtime.dart';
import 'package:ticket_app/features/scan/data/photo_picker.dart';
import 'package:ticket_app/features/scan/data/qr_scanner.dart';
import 'package:ticket_app/features/scan/data/repositories/scan_repository_impl.dart';
import 'package:ticket_app/features/scan/presentation/screens/scan_screen.dart';

import '../../scan_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

class _FakeRealtime implements ReceiptRealtime {
  final _receipt = StreamController<List<Map<String, dynamic>>>.broadcast();

  void emitReview(String id) => _receipt.add([
        {'id': id, 'status': 'review'},
      ]);

  @override
  Stream<List<Map<String, dynamic>>> watchReceipt(String id) => _receipt.stream;

  @override
  Stream<List<Map<String, dynamic>>> watchItems(String receiptId) =>
      Stream.value([
        {'raw_name': 'Молоко', 'qty': 1, 'unit_price': 2.5, 'sum': 2.5},
      ]);
}

void main() {
  testWidgets('галерея → processing → ревью позиций → подтверждение',
      (tester) async {
    final rt = _FakeRealtime();
    await pumpApp(
      tester,
      const ScanScreen(),
      overrides: [
        photoPickerProvider
            .overrideWithValue(FakePhotoPicker()..result = kValidPngBytes),
        scanRepositoryProvider
            .overrideWithValue(FakeScanRepository()..receiptId = 'r1'),
        receiptRealtimeProvider.overrideWithValue(rt),
        qrScannerProvider.overrideWithValue(FakeQrScanner()),
      ],
    );

    expect(find.text('Из галереи'), findsOneWidget);
    await tester.tap(find.text('Из галереи'));
    await tester.pump(); // pickFromGallery → recognizePhoto
    await tester.pump(); // ScanProcessing
    expect(find.text('Распознаём чек…'), findsOneWidget);

    rt.emitReview('r1');
    await tester.pumpAndSettle();

    expect(find.text('Подтвердить'), findsOneWidget);
    expect(find.text('Итого'), findsOneWidget);

    await tester.tap(find.text('Подтвердить'));
    await tester.pumpAndSettle();
    expect(find.text('Сканировать ещё'), findsOneWidget);
  });
}
