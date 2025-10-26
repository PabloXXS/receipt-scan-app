import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../widgets/sliver_pull_to_refresh.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import 'package:ticket_app/l10n/app_localizations.dart';

/// Профиль пользователя с настройками
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = Supabase.instance.client.auth.currentSession;
    final email = session?.user.email ?? '';

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: Text(AppLocalizations.of(context)!.profileTitle),
            backgroundColor:
                CupertinoColors.systemGroupedBackground.resolveFrom(context),
          ),
          BluePullToRefresh(
            backgroundColor:
                CupertinoColors.systemGroupedBackground.resolveFrom(context),
            topRadius: 0,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 800));
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              bottom: 16 + 72,
              top: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Аватар и email
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProfileHeader(email: email),
                ),
                const SizedBox(height: 24),

                // Настройки приложения
                const _SettingsSection(),
                const SizedBox(height: 24),

                // Дополнительные опции
                const _ExtraSection(),
                const SizedBox(height: 24),

                // Кнопка выхода
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SignOutButton(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Шапка профиля с аватаром и email
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Аватар с градиентом
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemBlue.resolveFrom(context),
                CupertinoColors.systemIndigo.resolveFrom(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemBlue
                    .resolveFrom(context)
                    .withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.person_fill,
            size: 50,
            color: CupertinoColors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Email
        if (email.isNotEmpty) ...[
          Text(
            email,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Активный аккаунт',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Секция настроек приложения
class _SettingsSection extends ConsumerWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      header: Text(
        AppLocalizations.of(context)!.settingsSection.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      children: <Widget>[
        // Темная тема
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemIndigo.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.moon_fill,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: Text(AppLocalizations.of(context)!.darkTheme),
          trailing: CupertinoSwitch(
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
          ),
        ),

        // Уведомления
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: Text(AppLocalizations.of(context)!.notifications),
          trailing: CupertinoSwitch(
            value: true,
            onChanged: (value) {
              // TODO: Реализовать управление уведомлениями
            },
          ),
        ),

        // Язык
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.globe,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: Text(AppLocalizations.of(context)!.language),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.russian,
                style: TextStyle(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
          onTap: () {
            // TODO: Реализовать выбор языка
          },
        ),
      ],
    );
  }
}

/// Секция дополнительных опций
class _ExtraSection extends StatelessWidget {
  const _ExtraSection();

  @override
  Widget build(BuildContext context) {
    return CupertinoListSection.insetGrouped(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      header: Text(
        AppLocalizations.of(context)!.extraSection.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      children: <Widget>[
        // Поддержка
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: Text(AppLocalizations.of(context)!.support),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          onTap: () {
            _showSupportDialog(context);
          },
        ),

        // О приложении
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.info_circle_fill,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: const Text('О приложении'),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          onTap: () {
            _showAboutDialog(context);
          },
        ),

        // Оценить приложение
        CupertinoListTile.notched(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemYellow.resolveFrom(context),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              CupertinoIcons.star_fill,
              size: 20,
              color: CupertinoColors.white,
            ),
          ),
          title: const Text('Оценить приложение'),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 16,
            color: CupertinoColors.tertiaryLabel.resolveFrom(context),
          ),
          onTap: () {
            // TODO: Открыть App Store/Play Market
          },
        ),
      ],
    );
  }

  void _showSupportDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Поддержка'),
        content: const Text(
          'Свяжитесь с нами:\nsupport@ticketapp.com\n\nМы ответим в течение 24 часов.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Закрыть'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Ticket App'),
        content: const Text(
          'Версия: 1.0.0\n\nПриложение для управления чеками и расходами.\n\n© 2025 Ticket App',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Закрыть'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Кнопка выхода из аккаунта
class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showSignOutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:
              CupertinoColors.systemRed.resolveFrom(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'Выйти из аккаунта',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemRed.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await Supabase.instance.client.auth.signOut();
              // Navigation will be handled by auth state listener
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }
}
