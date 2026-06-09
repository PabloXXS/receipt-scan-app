/// Назначение: экран установки нового пароля (в recovery-сессии).
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: presentation/controllers/auth_controller.dart, core/router/app_routes.dart,
///   core/error/failure.dart, shared/components.
/// Ключевые типы: ResetPasswordScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/auth_controller.dart';

/// Экран установки нового пароля.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_password.text);
    if (!ref.read(authControllerProvider).hasError && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return AppScaffold(
      title: 'Новый пароль',
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          AppTextField(
            label: 'Новый пароль',
            controller: _password,
            obscureText: true,
            prefixIcon: Icons.lock_outline,
          ),
          if (error != null) ...[
            SizedBox(height: tokens.spaceMd),
            Text(
              error is Failure ? error.message : 'Не удалось сменить пароль',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          AppButton(
            label: 'Сохранить',
            expanded: true,
            loading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
