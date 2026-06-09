/// Назначение: контроллер действий авторизации (состояние форм signIn/up/reset).
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: data/repositories/auth_repository_impl.dart (authRepositoryProvider),
///   domain/usecases/*.
/// Ключевые типы: AuthController, authControllerProvider.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/usecases/request_password_reset.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';

part 'auth_controller.g.dart';

/// Управляет асинхронным состоянием действий авторизации.
///
/// Состояние `AsyncValue<void>`: `data` — успех/простаивание, `loading` — в работе,
/// `error` — `AuthFailure`. Само наличие сессии и навигацию ведёт стрим в core/auth.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
  }

  /// Вход по email и паролю.
  Future<void> signIn({required String email, required String password}) =>
      _run(() => SignIn(ref.read(authRepositoryProvider))(
            email: email,
            password: password,
          ));

  /// Регистрация по email, паролю и стране.
  Future<void> signUp({
    required String email,
    required String password,
    required String countryCode,
  }) =>
      _run(() => SignUp(ref.read(authRepositoryProvider))(
            email: email,
            password: password,
            countryCode: countryCode,
          ));

  /// Выход из сессии.
  Future<void> signOut() =>
      _run(() => SignOut(ref.read(authRepositoryProvider))());

  /// Запрос письма для сброса пароля.
  Future<void> requestPasswordReset(String email) =>
      _run(() => RequestPasswordReset(ref.read(authRepositoryProvider))(email));

  /// Установка нового пароля.
  Future<void> resetPassword(String newPassword) =>
      _run(() => ResetPassword(ref.read(authRepositoryProvider))(newPassword));
}
