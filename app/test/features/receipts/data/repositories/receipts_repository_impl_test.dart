import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/repositories/receipts_repository_impl.dart';

import '../../receipts_test_fakes.dart';

void main() {
  test('list делегирует datasource и возвращает чеки', () async {
    final repo = ReceiptsRepositoryImpl(
        FakeReceiptsRemoteDataSource([makeReceipt('r1'), makeReceipt('r2')]));
    final page = await repo.list(limit: 25, offset: 0);
    expect(page.map((r) => r.id), ['r1', 'r2']);
  });

  test('delete делегирует datasource', () async {
    final ds = FakeReceiptsRemoteDataSource([makeReceipt('r1')]);
    await ReceiptsRepositoryImpl(ds).delete('r1');
    expect(ds.deleted, ['r1']);
  });

  test('исключение datasource → ReceiptsFailure', () async {
    final ds = FakeReceiptsRemoteDataSource([])
      ..error = const SocketException('x');
    final repo = ReceiptsRepositoryImpl(ds);
    expect(
        () => repo.list(limit: 25, offset: 0), throwsA(isA<ReceiptsFailure>()));
  });
}
