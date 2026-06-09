import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_tokens.dart';
import 'package:ticket_app/shared/components/price_delta_text.dart';

import '../../helpers/pump_component.dart';

void main() {
  test('directionOf по знаку дельты', () {
    expect(PriceDeltaText.directionOf(5), PriceDirection.up);
    expect(PriceDeltaText.directionOf(-5), PriceDirection.down);
    expect(PriceDeltaText.directionOf(0), PriceDirection.flat);
  });

  testWidgets('рост цены красит текст в priceUp', (tester) async {
    await pumpComponent(
      tester,
      const PriceDeltaText(delta: 10, currencyCode: 'USD', locale: 'en_US'),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppTokens.light.priceUp);
  });

  testWidgets('снижение цены красит текст в priceDown', (tester) async {
    await pumpComponent(
      tester,
      const PriceDeltaText(delta: -10, currencyCode: 'USD', locale: 'en_US'),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style?.color, AppTokens.light.priceDown);
  });
}
