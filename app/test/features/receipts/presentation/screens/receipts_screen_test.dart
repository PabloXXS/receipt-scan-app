import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/presentation/screens/receipts_screen.dart';
import 'package:ticket_app/features/receipts/presentation/widgets/receipt_list_item.dart';
import 'package:ticket_app/shared/components/components.dart';

import '../../receipts_test_fakes.dart';
import '../../../../helpers/pump_app.dart';

/// Свайпает первую строку и подтверждает удаление в диалоге.
Future<void> _swipeAndConfirmDelete(WidgetTester tester) async {
  await tester.drag(find.byType(ReceiptListItem).first, const Offset(-500, 0));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Удалить')); // действие свайпа открывает диалог
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(AppButton, 'Удалить')); // кнопка диалога
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('пустой список → AppEmptyState', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider
            .overrideWithValue(FakeReceiptsRepository([])),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppEmptyState), findsOneWidget);
  });

  testWidgets('есть чеки → рендерятся строки списка', (tester) async {
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [
        receiptsRepositoryProvider.overrideWithValue(
          FakeReceiptsRepository(
              [makeReceipt('r1'), makeReceipt('r2'), makeReceipt('r3')]),
        ),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptListItem), findsNWidgets(3));
  });

  testWidgets('ошибка загрузки → AppErrorView', (tester) async {
    final repo = FakeReceiptsRepository([])
      ..error = Exception('boom'); // станет AsyncError
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [receiptsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppErrorView), findsOneWidget);
  });

  testWidgets(
      'успешное удаление + упавший перезапрос → AppErrorView, без SnackBar',
      (tester) async {
    final repo = FakeReceiptsRepository(
      [makeReceipt('r1'), makeReceipt('r2'), makeReceipt('r3')],
    )..failListAfterDelete = true;
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [receiptsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    await _swipeAndConfirmDelete(tester);

    // Удаление прошло; ошибка перезапроса видна в списке — SnackBar не нужен.
    expect(repo.deleted, ['r1']);
    expect(find.byType(AppErrorView), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('ошибка удаления → SnackBar с сообщением', (tester) async {
    final repo = FakeReceiptsRepository(
      [makeReceipt('r1'), makeReceipt('r2'), makeReceipt('r3')],
    )..deleteError = const ReceiptsDeleteFailure();
    await pumpApp(
      tester,
      const ReceiptsScreen(),
      overrides: [receiptsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.pumpAndSettle();

    await _swipeAndConfirmDelete(tester);

    expect(repo.deleted, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text(const ReceiptsDeleteFailure().message),
      findsOneWidget,
    );
    // Сливаем таймер автоскрытия SnackBar, чтобы не висел после теста.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
