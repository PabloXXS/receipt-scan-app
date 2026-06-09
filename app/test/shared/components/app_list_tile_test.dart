import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_list_tile.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает title/subtitle и реагирует на тап', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      AppListTile(title: 'Чек №1', subtitle: 'Магазин', onTap: () => taps++),
    );
    expect(find.text('Чек №1'), findsOneWidget);
    expect(find.text('Магазин'), findsOneWidget);
    await tester.tap(find.text('Чек №1'));
    await tester.pump();
    expect(taps, 1);
  });
}
