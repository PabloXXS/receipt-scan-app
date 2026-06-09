import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';

void main() {
  test('ScanFailure — подтип Failure с человекочитаемым message', () {
    const failures = <ScanFailure>[
      CameraPermissionDeniedFailure(),
      UploadFailure(),
      ScanNetworkFailure(),
      UnknownScanFailure(),
    ];
    for (final f in failures) {
      expect(f, isA<Failure>());
      expect(f.message, isNotEmpty);
    }
  });
}
