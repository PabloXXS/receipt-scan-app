import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет пустого состояния аналитики
class EmptyAnalyticsState extends ConsumerWidget {
  const EmptyAnalyticsState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 80,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет данных для аналитики',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Добавьте первый чек, чтобы увидеть статистику и графики',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () {
                // Переключаемся на главную страницу (index 0)
                // Предполагается, что это будет обработано на уровне навигации
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.add_circled_solid, size: 20),
                  SizedBox(width: 8),
                  Text('Добавить чек'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

