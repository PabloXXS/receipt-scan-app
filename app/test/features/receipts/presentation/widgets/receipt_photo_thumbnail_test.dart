import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_photo_thumbnail.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  testWidgets('без photoPath показывает иконку-плейсхолдер', (tester) async {
    await pumpApp(tester, const ReceiptPhotoThumbnail(photoPath: null));
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
