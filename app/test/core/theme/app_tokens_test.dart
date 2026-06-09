import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_colors.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';

void main() {
  test('шкала spacing и radii', () {
    const t = AppTokens.light;
    expect(t.spaceXs, 4);
    expect(t.spaceMd, 12);
    expect(t.spaceXxl, 32);
    expect(t.radiusMd, 12);
    expect(t.radiusPill, 999);
  });

  test('семантические цвета берутся из AppColors по теме', () {
    expect(AppTokens.light.priceUp, AppColors.priceUpLight);
    expect(AppTokens.dark.priceUp, AppColors.priceUpDark);
  });

  test('lerp при t=0 возвращает исходные цвета', () {
    final r = AppTokens.light.lerp(AppTokens.dark, 0);
    expect(r.priceUp, AppColors.priceUpLight);
    expect(r.spaceMd, 12);
  });

  test('lerp при t=1 возвращает целевые цвета', () {
    final r = AppTokens.light.lerp(AppTokens.dark, 1);
    expect(r.priceUp, AppColors.priceUpDark);
  });

  testWidgets('context.tokens достаёт расширение из темы', (tester) async {
    late AppTokens captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        home: Builder(
          builder: (context) {
            captured = context.tokens;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(captured.spaceMd, 12);
  });
}
