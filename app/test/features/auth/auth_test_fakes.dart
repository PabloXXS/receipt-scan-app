import 'package:ticket_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ticket_app/features/auth/domain/repositories/auth_repository.dart';

/// Управляемый фейк источника данных: бросает заданное исключение либо
/// записывает факт вызова.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Object? error;
  final List<String> calls = [];

  void _maybeThrow(String name) {
    calls.add(name);
    if (error != null) throw error!;
  }

  @override
  Future<void> signIn(
          {required String email, required String password}) async =>
      _maybeThrow('signIn');

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  }) async =>
      _maybeThrow('signUp');

  @override
  Future<void> signOut() async => _maybeThrow('signOut');

  @override
  Future<void> sendPasswordResetEmail(String email) async =>
      _maybeThrow('sendPasswordResetEmail');

  @override
  Future<void> updatePassword(String newPassword) async =>
      _maybeThrow('updatePassword');
}

/// Фейк репозитория для тестов use-case'ов и контроллера.
class FakeAuthRepository implements AuthRepository {
  Object? error;
  final List<String> calls = [];

  Future<void> _run(String name) async {
    calls.add(name);
    if (error != null) throw error!;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _run('signIn');

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  }) =>
      _run('signUp');

  @override
  Future<void> signOut() => _run('signOut');

  @override
  Future<void> requestPasswordReset(String email) =>
      _run('requestPasswordReset');

  @override
  Future<void> resetPassword(String newPassword) => _run('resetPassword');
}
