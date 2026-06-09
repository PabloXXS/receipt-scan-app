import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ticket_app/features/auth/presentation/controllers/auth_controller.dart';

import '../../auth_test_fakes.dart';

ProviderContainer _containerWith(FakeAuthRepository repo) {
  final c = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('начальное состояние — AsyncData(null)', () {
    final c = _containerWith(FakeAuthRepository());
    expect(c.read(authControllerProvider), const AsyncData<void>(null));
  });

  test('успешный signIn → AsyncData', () async {
    final repo = FakeAuthRepository();
    final c = _containerWith(repo);
    await c
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.c', password: 'x');
    expect(c.read(authControllerProvider), isA<AsyncData<void>>());
    expect(repo.calls, contains('signIn'));
  });

  test('ошибка signIn → AsyncError с AuthFailure', () async {
    final repo = FakeAuthRepository()
      ..error = const InvalidCredentialsFailure();
    final c = _containerWith(repo);
    await c
        .read(authControllerProvider.notifier)
        .signIn(email: 'a@b.c', password: 'x');
    final state = c.read(authControllerProvider);
    expect(state, isA<AsyncError<void>>());
    expect(state.error, isA<InvalidCredentialsFailure>());
  });

  test('signUp передаёт countryCode и завершается AsyncData', () async {
    final repo = FakeAuthRepository();
    final c = _containerWith(repo);
    await c
        .read(authControllerProvider.notifier)
        .signUp(email: 'a@b.c', password: 'x', countryCode: 'BY');
    expect(c.read(authControllerProvider), isA<AsyncData<void>>());
    expect(repo.calls, contains('signUp'));
  });
}
