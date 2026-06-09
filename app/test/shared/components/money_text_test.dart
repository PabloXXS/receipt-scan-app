import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/money_text.dart';

import '../../helpers/pump_component.dart';

void main() {
  test('format USD/en_US даёт привычный вид', () {
    expect(
      MoneyText.format(1234.5, currencyCode: 'USD', locale: 'en_US'),
      r'$1,234.50',
    );
  });

  test('format RUB/ru содержит символ рубля', () {
    final s = MoneyText.format(1234.5, currencyCode: 'RUB', locale: 'ru');
    expect(s.contains('₽'), isTrue);
  });

  testWidgets('рендерит отформатированную сумму', (tester) async {
    await pumpComponent(
      tester,
      const MoneyText(1234.5, currencyCode: 'USD', locale: 'en_US'),
    );
    expect(find.text(r'$1,234.50'), findsOneWidget);
  });
}
