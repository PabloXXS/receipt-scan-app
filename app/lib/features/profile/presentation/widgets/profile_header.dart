/// Назначение: шапка настроек — аватар, имя, email; тап ведёт к редактированию.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart,
///   shared/components/components.dart, domain/entities/profile.dart.
/// Ключевые типы: ProfileHeader.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../../domain/entities/profile.dart';

/// Карточка с аватаром, именем и email пользователя.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.profile,
    required this.email,
    this.onTap,
    super.key,
  });

  final Profile profile;
  final String? email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final name = profile.displayName?.trim().isNotEmpty == true
        ? profile.displayName!
        : 'Без имени';

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: tokens.avatarRadiusSm,
            backgroundColor: scheme.primaryContainer,
            foregroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: Text(
              _initials(name),
              style: textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: textTheme.titleMedium),
                if (email != null)
                  Text(
                    email!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '?';
    return first.toUpperCase();
  }
}
