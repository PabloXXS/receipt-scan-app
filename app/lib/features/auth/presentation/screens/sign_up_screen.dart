/// Назначение: экран регистрации по email, паролю и стране.
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: presentation/controllers/auth_controller.dart, widgets/country_field.dart,
///   core/router/app_routes.dart, core/error/failure.dart, shared/components.
/// Ключевые типы: SignUpScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/auth_controller.dart';
import '../widgets/country_field.dart';

/// Экран регистрации.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _country;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final country = _country;
    if (country == null) return;
    await ref.read(authControllerProvider.notifier).signUp(
          email: _email.text.trim(),
          password: _password.text,
          countryCode: country,
        );
    if (!ref.read(authControllerProvider).hasError && mounted) {
      context.go(AppRoutes.checkEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return AppScaffold(
      title: 'Регистрация',
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
          SizedBox(height: tokens.spaceMd),
          CountryField(
            value: _country,
            onChanged: (v) => setState(() => _country = v),
          ),
          if (error != null) ...[
            SizedBox(height: tokens.spaceMd),
            Text(
              error is Failure
                  ? error.message
                  : 'Не удалось зарегистрироваться',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          AppButton(
            label: 'Зарегистрироваться',
            expanded: true,
            loading: state.isLoading,
            onPressed: _country == null ? null : _submit,
          ),
          AppButton(
            label: 'Уже есть аккаунт? Войти',
            variant: AppButtonVariant.text,
            onPressed: () => context.go(AppRoutes.signIn),
          ),
        ],
      ),
    );
  }
}
