/// Назначение: квадратная миниатюра фото чека (signed URL) или плейсхолдер.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, core/theme/app_tokens.dart,
///   controllers/receipt_details_controller.dart.
/// Ключевые типы: ReceiptPhotoThumbnail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../controllers/receipt_details_controller.dart';

/// Миниатюра фото чека размером [size]; при отсутствии фото — иконка.
class ReceiptPhotoThumbnail extends ConsumerWidget {
  const ReceiptPhotoThumbnail(
      {required this.photoPath, this.size = 56, super.key});

  final String? photoPath;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(tokens.radiusSm);

    Widget placeholder() => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: radius,
          ),
          child:
              Icon(Icons.receipt_long_outlined, color: scheme.onSurfaceVariant),
        );

    final path = photoPath;
    if (path == null) return placeholder();

    final urlAsync = ref.watch(receiptPhotoUrlProvider(path));
    return ClipRRect(
      borderRadius: radius,
      child: urlAsync.maybeWhen(
        data: (url) => url == null
            ? placeholder()
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder(),
              ),
        orElse: placeholder,
      ),
    );
  }
}
