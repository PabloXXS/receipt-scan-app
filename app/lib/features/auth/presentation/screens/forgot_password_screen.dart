/// Назначение: экран запроса письма для сброса пароля.
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: presentation/controllers/auth_controller.dart, core/router/app_routes.dart,
///   core/error/failure.dart, shared/components.
/// Ключевые типы: ForgotPasswordScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/auth_controller.dart';

/// Экран восстановления пароля.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(_email.text.trim());
    if (!ref.read(authControllerProvider).hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Письмо отправлено, проверьте почту')),
      );
      context.go(AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(authControllerProvider);
    final error = state.error;

    return AppScaffold(
      title: 'Восстановление пароля',
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceLg),
        children: [
          Text(
            'Укажите email — пришлём ссылку для сброса пароля.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.spaceMd),
          AppTextField(
            label: 'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          if (error != null) ...[
            SizedBox(height: tokens.spaceMd),
            Text(
              error is Failure ? error.message : 'Не удалось отправить письмо',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          SizedBox(height: tokens.spaceLg),
          AppButton(
            label: 'Отправить ссылку',
            expanded: true,
            loading: state.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
