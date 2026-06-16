import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';
import 'package:ticket_app/features/receipts/domain/entities/receipt.dart';
import 'package:ticket_app/features/receipts/presentation/controllers/receipts_list_controller.dart';

import '../../receipts_test_fakes.dart';

ProviderContainer _container(FakeReceiptsRepository repo) {
  final c = ProviderContainer(overrides: [
    receiptsRepositoryProvider.overrideWithValue(repo),
  ]);
  addTearDown(c.dispose);
  return c;
}

List<Receipt> _receipts(int n) =>
    List<Receipt>.generate(n, (i) => makeReceipt('r$i'));

void main() {
  test('первая загрузка отдаёт 25 и hasMore=true при 30 чеках', () async {
    final c = _container(FakeReceiptsRepository(_receipts(30)));
    final state = await c.read(receiptsListControllerProvider.future);
    expect(state.items.length, 25);
    expect(state.hasMore, isTrue);
  });

  test('loadMore догружает остаток и ставит hasMore=false', () async {
    final c = _container(FakeReceiptsRepository(_receipts(30)));
    await c.read(receiptsListControllerProvider.future);
    await c.read(receiptsListControllerProvider.notifier).loadMore();
    final state = c.read(receiptsListControllerProvider).requireValue;
    expect(state.items.length, 30);
    expect(state.hasMore, isFalse);
  });

  test(
      'ровно 25 чеков: hasMore=true после первой страницы, false после пустой догрузки',
      () async {
    // Offset-пагинация не может на первой странице отличить «ровно 25» от «есть ещё»:
    // обе возвращают 25 строк. Конвенция: hasMore=true, пока страница полная;
    // флаг сбрасывается, когда следующая догрузка вернёт меньше pageSize (тут — пусто).
    final c = _container(FakeReceiptsRepository(_receipts(25)));
    final first = await c.read(receiptsListControllerProvider.future);
    expect(first.items.length, 25);
    expect(first.hasMore, isTrue);
    await c.read(receiptsListControllerProvider.notifier).loadMore();
    final after = c.read(receiptsListControllerProvider).requireValue;
    expect(after.items.length, 25);
    expect(after.hasMore, isFalse);
  });

  test('deleteReceipt удаляет и перезапрашивает список', () async {
    final repo = FakeReceiptsRepository(_receipts(3));
    final c = _container(repo);
    await c.read(receiptsListControllerProvider.future);
    await c.read(receiptsListControllerProvider.notifier).deleteReceipt('r0');
    final state = c.read(receiptsListControllerProvider).requireValue;
    expect(repo.deleted, ['r0']);
    expect(state.items.map((r) => r.id), ['r1', 'r2']);
  });

  test(
      'успешное удаление + упавший перезапрос → AsyncError(ReceiptsLoadFailure), '
      'удаление зафиксировано', () async {
    final repo = FakeReceiptsRepository(_receipts(3))
      ..failListAfterDelete = true;
    final c = _container(repo);
    await c.read(receiptsListControllerProvider.future);
    await expectLater(
      c.read(receiptsListControllerProvider.notifier).deleteReceipt('r0'),
      throwsA(isA<ReceiptsLoadFailure>()),
    );
    // Удаление прошло (repo зафиксировал id) — ошибка относится к перезапросу.
    expect(repo.deleted, ['r0']);
    final state = c.read(receiptsListControllerProvider);
    expect(state, isA<AsyncError<ReceiptsListState>>());
    expect(state.error, isA<ReceiptsLoadFailure>());
    expect(state.error, isNot(isA<ReceiptsDeleteFailure>()));
  });

  test('ошибка загрузки → AsyncError(ReceiptsFailure)', () async {
    final repo = FakeReceiptsRepository([])
      ..error = const ReceiptsLoadFailure();
    final c = _container(repo);
    await expectLater(
      c.read(receiptsListControllerProvider.future),
      throwsA(isA<ReceiptsFailure>()),
    );
  });
}
