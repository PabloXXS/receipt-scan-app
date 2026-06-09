import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Глобальная настройка тестов: отключает сетевую подгрузку google_fonts и
/// глушит async-ошибки загрузки шрифта (нет bundled-ассета в тестах).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('GoogleFonts') ||
        msg.contains('allowRuntimeFetching') ||
        msg.contains('Inter')) {
      return;
    }
    previous?.call(details);
  };
  await testMain();
}
