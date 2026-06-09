/// Назначение: экран входа по email и паролю.
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: presentation/controllers/auth_controller.dart, core/router/app_routes.dart,
///   core/error/failure.dart, shared/components.
/// Ключевые типы: SignInScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/auth_controller.dart';

/// Экран входа.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
    // Успешный вход уводит redirect автоматически по стриму сессии.
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return AppScaffold(
      title: 'Вход',
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          AppTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          SizedBox(height: tokens.spaceMd),
          AppTextField(
            label: 'Пароль',
            controller: _password,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          if (error != null) ...[
            SizedBox(height: tokens.spaceMd),
            Text(
              error is Failure ? error.message : 'Не удалось войти',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          AppButton(
            label: 'Войти',
            expanded: true,
            loading: state.isLoading,
            onPressed: _submit,
          ),
          SizedBox(height: tokens.spaceSm),
          AppButton(
            label: 'Забыли пароль?',
            variant: AppButtonVariant.text,
            onPressed: () => context.go(AppRoutes.forgotPassword),
          ),
          AppButton(
            label: 'Нет аккаунта? Регистрация',
            variant: AppButtonVariant.text,
            onPressed: () => context.go(AppRoutes.signUp),
          ),
        ],
      ),
    );
  }
}
