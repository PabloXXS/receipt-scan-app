/// Назначение: экран-заглушка раздела «Профиль» + выход из аккаунта.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: auth/presentation/controllers/auth_controller.dart, shared/components,
///   core/theme/app_tokens.dart.
/// Ключевые типы: ProfileScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Экран-заглушка профиля с кнопкой выхода.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AppScaffold(
      title: 'Профиль',
      body: Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          children: [
            const Expanded(
              child: AppEmptyState(
                message: 'Профиль и настройки появятся здесь.',
                icon: Icons.person_outline,
              ),
            ),
            AppButton(
              label: 'Выйти',
              variant: AppButtonVariant.destructive,
              expanded: true,
              loading: isLoading,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}
