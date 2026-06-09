/// Назначение: реализация AuthRepository поверх AuthRemoteDataSource.
///
/// Слой: data
/// Фича: auth
/// Зависимости: datasources/auth_remote_datasource.dart, auth_error_mapper.dart,
///   domain/repositories/auth_repository.dart.
/// Ключевые типы: AuthRepositoryImpl, authRepositoryProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../auth_error_mapper.dart';
import '../datasources/auth_remote_datasource.dart';

/// Реализация контракта авторизации; маппит исключения в `AuthFailure`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._ds);

  final AuthRemoteDataSource _ds;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      throw mapAuthException(e);
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _ds.signIn(email: email, password: password));

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  }) =>
      _guard(() => _ds.signUp(
            email: email,
            password: password,
            countryCode: countryCode,
          ));

  @override
  Future<void> signOut() => _guard(_ds.signOut);

  @override
  Future<void> requestPasswordReset(String email) =>
      _guard(() => _ds.sendPasswordResetEmail(email));

  @override
  Future<void> resetPassword(String newPassword) =>
      _guard(() => _ds.updatePassword(newPassword));
}

/// DI-провайдер репозитория авторизации.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider)),
);
