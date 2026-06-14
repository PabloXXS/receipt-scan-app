/// Назначение: скелетон карточки профиля на время сетевой загрузки.
///
/// Слой: presentation
/// Фича: profile
/// Зависимости: flutter material, core/theme/app_tokens.dart,
///   shared/components/components.dart.
/// Ключевые типы: ProfileHeaderSkeleton.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';

const double _kNameLineWidth = 140;
const double _kEmailLineWidth = 200;
const double _kNameLineHeight = 16;
const double _kEmailLineHeight = 12;

/// Плейсхолдер карточки профиля (аватар + две строки).
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final avatar = tokens.avatarRadiusSm * 2;
    return AppCard(
      child: Row(
        children: [
          AppSkeleton(width: avatar, height: avatar, shape: BoxShape.circle),
          SizedBox(width: tokens.spaceMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSkeleton(
                  width: _kNameLineWidth, height: _kNameLineHeight),
              SizedBox(height: tokens.spaceSm),
              const AppSkeleton(
                  width: _kEmailLineWidth, height: _kEmailLineHeight),
            ],
          ),
        ],
      ),
    );
  }
}
