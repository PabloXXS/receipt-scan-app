import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/auth/data/repositories/auth_repository_impl.dart';

import '../../auth_test_fakes.dart';

void main() {
  late FakeAuthRemoteDataSource ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = FakeAuthRemoteDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  test('signIn делегирует источнику данных', () async {
    await repo.signIn(email: 'a@b.c', password: 'secret');
    expect(ds.calls, contains('signIn'));
  });

  test('signIn оборачивает AuthException в AuthFailure', () async {
    ds.error = AuthApiException('Invalid login credentials',
        code: 'invalid_credentials');
    expect(
      () => repo.signIn(email: 'a@b.c', password: 'x'),
      throwsA(isA<InvalidCredentialsFailure>()),
    );
  });

  test('resetPassword делегирует updatePassword', () async {
    await repo.resetPassword('newpass');
    expect(ds.calls, contains('updatePassword'));
  });

  test('requestPasswordReset делегирует sendPasswordResetEmail', () async {
    await repo.requestPasswordReset('a@b.c');
    expect(ds.calls, contains('sendPasswordResetEmail'));
  });
}
