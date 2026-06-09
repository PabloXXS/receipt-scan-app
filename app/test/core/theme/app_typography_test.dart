import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_app/core/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('textTheme возвращает заполненную типографику на базе исходной', () {
    const base = Typography.englishLike2021;
    final theme = AppTypography.textTheme(base);
    expect(theme.bodyMedium, isNotNull);
    expect(theme.titleLarge, isNotNull);
  });
}
