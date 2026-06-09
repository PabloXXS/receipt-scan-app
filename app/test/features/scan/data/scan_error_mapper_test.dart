import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/scan/data/scan_error_mapper.dart';

void main() {
  test('SocketException → ScanNetworkFailure', () {
    expect(mapScanException(const SocketException('x')),
        isA<ScanNetworkFailure>());
  });

  test('PlatformException camera/photo access → CameraPermissionDeniedFailure',
      () {
    expect(mapScanException(PlatformException(code: 'camera_access_denied')),
        isA<CameraPermissionDeniedFailure>());
    expect(mapScanException(PlatformException(code: 'photo_access_denied')),
        isA<CameraPermissionDeniedFailure>());
  });

  test('StorageException → UploadFailure', () {
    expect(mapScanException(const StorageException('x')), isA<UploadFailure>());
  });

  test('PostgrestException → UploadFailure', () {
    expect(mapScanException(const PostgrestException(message: 'x')),
        isA<UploadFailure>());
  });

  test('уже ScanFailure возвращается как есть', () {
    const f = CameraPermissionDeniedFailure();
    expect(mapScanException(f), same(f));
  });

  test('прочее → UnknownScanFailure', () {
    expect(mapScanException(Exception('x')), isA<UnknownScanFailure>());
  });
}
