/// Назначение: информирование о письме подтверждения email.
///
/// Слой: presentation
/// Фича: auth
/// Зависимости: core/router/app_routes.dart, shared/components.
/// Ключевые типы: CheckEmailScreen.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';

/// Экран «проверьте почту».
class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AppScaffold(
      title: 'Подтвердите email',
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_unread_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: tokens.spaceLg),
            Text(
              'Мы отправили письмо со ссылкой подтверждения. '
              'Откройте её, чтобы завершить регистрацию.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: tokens.spaceXl),
            AppButton(
              label: 'На страницу входа',
              variant: AppButtonVariant.secondary,
              onPressed: () => context.go(AppRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
