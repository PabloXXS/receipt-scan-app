/// Назначение: экран «Настройки» — профиль, страна, тема, пароль, семья, выход.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, flutter_riverpod, go_router,
///   core/theme/*, core/auth, core/router, shared/components,
///   auth/presentation/controllers/auth_controller.dart, profile presentation,
///   domain/entities/profile.dart.
/// Ключевые типы: SettingsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/constants/supported_countries.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_mode_controller.dart';
import '../../../../shared/components/components.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/profile.dart';
import '../controllers/profile_controller.dart';
import '../widgets/country_picker_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/theme_mode_sheet.dart';

/// Экран настроек приложения и профиля.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileControllerProvider);
    final email = ref.watch(currentUserEmailProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    final profile = profileAsync.valueOrNull;
    final body = profile == null
        ? (profileAsync.hasError
            ? AppErrorView(
                message: 'Не удалось загрузить профиль',
                onRetry: () => ref.invalidate(profileControllerProvider),
              )
            : const AppLoader())
        : _buildList(context, ref, profile, email, themeMode, isSigningOut);
    return AppScaffold(title: 'Настройки', body: body);
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
    String? email,
    ThemeMode themeMode,
    bool isSigningOut,
  ) {
    final tokens = context.tokens;
    return ListView(
      padding: EdgeInsets.all(tokens.spaceLg),
      children: [
        ProfileHeader(
          profile: profile,
          email: email,
          onTap: () => context.push(AppRoutes.editProfile),
        ),
        SizedBox(height: tokens.spaceLg),
        AppListTile(
          title: 'Страна',
          subtitle: countryName(profile.countryCode),
          leading: const Icon(Icons.public),
          onTap: () => _changeCountry(context, ref, profile.countryCode),
        ),
        AppListTile(
          title: 'Сменить пароль',
          leading: const Icon(Icons.lock_outline),
          onTap: () => context.push(AppRoutes.resetPassword),
        ),
        SizedBox(height: tokens.spaceMd),
        AppListTile(
          title: 'Тема оформления',
          subtitle: _themeLabel(themeMode),
          leading: const Icon(Icons.brightness_6_outlined),
          onTap: () => _changeTheme(context, ref, themeMode),
        ),
        SizedBox(height: tokens.spaceMd),
        const AppListTile(
          title: 'Семья',
          subtitle: 'Скоро',
          leading: Icon(Icons.group_outlined),
          // onTap намеренно не задан — раздел в разработке.
        ),
        SizedBox(height: tokens.spaceXl),
        AppButton(
          label: 'Выйти',
          variant: AppButtonVariant.destructive,
          expanded: true,
          loading: isSigningOut,
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
      ],
    );
  }

  Future<void> _changeCountry(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final picked = await showCountryPicker(context, current: current);
    if (picked == null || picked == current || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сменить страну?'),
        content: const Text(
          'Изменятся фискальный провайдер и валюта будущих чеков. '
          'Ранее сохранённые чеки не изменятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сменить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(profileControllerProvider.notifier).setCountry(picked);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось сменить страну')),
          );
        }
      }
    }
  }

  Future<void> _changeTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showThemeModePicker(context, current: current);
    if (picked == null) return;
    await ref.read(themeModeControllerProvider.notifier).setMode(picked);
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
        ThemeMode.system => 'Системная',
      };
}
