import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/shared/components/app_text_field.dart';

import '../../helpers/pump_component.dart';

void main() {
  testWidgets('показывает label и отдаёт ввод через onChanged', (tester) async {
    String? value;
    await pumpComponent(
      tester,
      AppTextField(label: 'Email', onChanged: (v) => value = v),
    );
    expect(find.text('Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'a@b.c');
    expect(value, 'a@b.c');
  });

  testWidgets('показывает текст ошибки', (tester) async {
    await pumpComponent(
      tester,
      const AppTextField(label: 'Email', errorText: 'Неверный email'),
    );
    expect(find.text('Неверный email'), findsOneWidget);
  });
}
