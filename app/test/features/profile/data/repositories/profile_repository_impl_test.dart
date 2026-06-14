import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/profile/data/repositories/profile_repository_impl.dart';

import '../../profile_test_fakes.dart';

void main() {
  test('getCurrent делегирует datasource', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.getCurrent();
    expect(p.id, 'u1');
  });

  test('updateName сохраняет имя', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.updateName('Боря');
    expect(p.displayName, 'Боря');
  });

  test('сетевая ошибка → ProfileNetworkFailure', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile())
      ..error = const SocketException('no net');
    final repo = ProfileRepositoryImpl(ds);
    expect(repo.getCurrent(), throwsA(isA<ProfileNetworkFailure>()));
  });

  test('updateAvatar возвращает профиль с avatar_url', () async {
    final ds = FakeProfileRemoteDataSource(makeProfile());
    final repo = ProfileRepositoryImpl(ds);
    final p = await repo.updateAvatar(Uint8List(0));
    expect(p.avatarUrl, isNotNull);
  });
}
