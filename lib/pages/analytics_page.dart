import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sliver_pull_to_refresh.dart';
import '../providers/receipts_provider.dart';
import '../providers/item_categories_provider.dart';
import '../models/item_category.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _Content();
  }
}

class _Content extends ConsumerWidget {
  const _Content();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);
    final categoriesAsync = ref.watch(itemCategoriesProvider);

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: CustomScrollView(
        slivers: <Widget>[
          CupertinoSliverNavigationBar(
            largeTitle: const Text('Аналитика'),
            backgroundColor:
                CupertinoColors.systemGroupedBackground.resolveFrom(context),
          ),
          BluePullToRefresh(
            backgroundColor:
                CupertinoColors.systemGroupedBackground.resolveFrom(context),
            topRadius: 0,
            onRefresh: () async {
              await Future.wait([
                ref.read(receiptsProvider.notifier).refresh(),
                ref.read(itemCategoriesProvider.notifier).refresh(),
              ]);
            },
          ),
          receiptsAsync.when(
            data: (receipts) {
              if (receipts.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                );
              }

              return categoriesAsync.when(
                data: (categories) {
                  // Подсчет статистики будет реализован позже
                  // Сейчас показываем список доступных категорий
                  return SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _SummaryCard(receipts: receipts),
                        const SizedBox(height: 16),
                        _CategoriesSection(categories: categories),
                      ]),
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _ErrorState(error: error),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: _ErrorState(error: error),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.receipts});

  final List receipts;

  @override
  Widget build(BuildContext context) {
    final total = receipts.fold<double>(
      0,
      (sum, receipt) => sum + (receipt.total as double),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Всего чеков',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${receipts.length}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Общая сумма',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${total.toStringAsFixed(2)} ₽',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({required this.categories});

  final List<ItemCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 16, 8),
          child: Text(
            'КАТЕГОРИИ ТОВАРОВ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              for (var i = 0; i < categories.length; i++)
                _CategoryRow(
                  category: categories[i],
                  isLast: i == categories.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    this.isLast = false,
  });

  final ItemCategory category;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator.resolveFrom(context),
                  width: 0.5,
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 64,
              color: CupertinoColors.tertiaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных для аналитики',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Добавьте чеки, чтобы увидеть статистику',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              '$error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
