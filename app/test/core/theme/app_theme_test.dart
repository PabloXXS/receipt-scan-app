import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_app/core/theme/app_theme.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // google_fonts v8 fires async font-load errors when running without bundled
  // font assets; suppress them so they don't fail the structural theme tests.
  setUp(() {
    FlutterError.onError = (details) {
      final msg = details.exception.toString();
      if (msg.contains('allowRuntimeFetching') || msg.contains('Inter')) return;
      FlutterError.presentError(details);
    };
  });
  tearDown(() => FlutterError.onError = FlutterError.presentError);

  testWidgets('светлая тема: M3, brightness light, токены прикреплены',
      (tester) async {
    final theme = AppTheme.light();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.extension<AppTokens>(), isNotNull);
    expect(theme.extension<AppTokens>()!.priceUp, AppTokens.light.priceUp);
    await tester.pump(); // drain async font-load side-effects
  });

  testWidgets('тёмная тема: brightness dark, тёмные токены', (tester) async {
    final theme = AppTheme.dark();
    expect(theme.colorScheme.brightness, Brightness.dark);
    expect(theme.extension<AppTokens>()!.priceUp, AppTokens.dark.priceUp);
    await tester.pump(); // drain async font-load side-effects
  });
}
