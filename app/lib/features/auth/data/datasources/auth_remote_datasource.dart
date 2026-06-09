/// Назначение: доступ к Supabase Auth (GoTrue) для операций авторизации.
///
/// Слой: data
/// Фича: auth
/// Зависимости: supabase_flutter, core/supabase/supabase_providers.dart,
///   core/config/app_config.dart.
/// Ключевые типы: AuthRemoteDataSource, SupabaseAuthRemoteDataSource,
///   authRemoteDataSourceProvider.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/supabase/supabase_providers.dart';

/// Абстракция операций авторизации над удалённым провайдером.
abstract interface class AuthRemoteDataSource {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword(String newPassword);
}

/// Реализация поверх Supabase GoTrue. Пробрасывает `AuthException` наверх.
class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  const SupabaseAuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      data: {'country_code': countryCode},
      emailRedirectTo: AppConfig.authRedirectUrl,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _auth.resetPasswordForEmail(email, redirectTo: AppConfig.authRedirectUrl);

  @override
  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }
}

/// DI-провайдер источника данных авторизации.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => SupabaseAuthRemoteDataSource(ref.watch(supabaseClientProvider)),
);
