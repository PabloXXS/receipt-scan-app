import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/features/auth/domain/usecases/request_password_reset.dart';
import 'package:ticket_app/features/auth/domain/usecases/reset_password.dart';
import 'package:ticket_app/features/auth/domain/usecases/sign_in.dart';
import 'package:ticket_app/features/auth/domain/usecases/sign_out.dart';
import 'package:ticket_app/features/auth/domain/usecases/sign_up.dart';

import '../../auth_test_fakes.dart';

void main() {
  late FakeAuthRepository repo;

  setUp(() => repo = FakeAuthRepository());

  test('SignIn вызывает repo.signIn', () async {
    await SignIn(repo)(email: 'a@b.c', password: 'x');
    expect(repo.calls, ['signIn']);
  });

  test('SignUp вызывает repo.signUp', () async {
    await SignUp(repo)(email: 'a@b.c', password: 'x', countryCode: 'BY');
    expect(repo.calls, ['signUp']);
  });

  test('SignOut вызывает repo.signOut', () async {
    await SignOut(repo)();
    expect(repo.calls, ['signOut']);
  });

  test('RequestPasswordReset вызывает repo.requestPasswordReset', () async {
    await RequestPasswordReset(repo)('a@b.c');
    expect(repo.calls, ['requestPasswordReset']);
  });

  test('ResetPassword вызывает repo.resetPassword', () async {
    await ResetPassword(repo)('newpass');
    expect(repo.calls, ['resetPassword']);
  });
}
