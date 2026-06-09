import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_chip.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает label и переключает выбор', (tester) async {
    bool? selected;
    await pumpComponent(
      tester,
      AppChip(
        label: 'Продукты',
        selected: false,
        onSelected: (v) => selected = v,
      ),
    );
    expect(find.text('Продукты'), findsOneWidget);
    await tester.tap(find.text('Продукты'));
    await tester.pump();
    expect(selected, isTrue);
  });
}
