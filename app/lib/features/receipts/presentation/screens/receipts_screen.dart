/// Назначение: экран списка чеков — пагинация по скроллу, pull-to-refresh, удаление.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: flutter material, flutter_riverpod, go_router, core/theme/app_tokens.dart,
///   core/router/app_routes.dart, shared/components, controllers/receipts_list_controller.dart,
///   widgets/receipt_list_item.dart.
/// Ключевые типы: ReceiptsScreen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/components/components.dart';
import '../controllers/receipts_list_controller.dart';
import '../widgets/receipt_list_item.dart';

/// Список чеков пользователя.
class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(receiptsListControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ref.read(receiptsListControllerProvider.notifier).deleteReceipt(id);
    } on ReceiptsDeleteFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      // Удаление прошло, но упал перезапрос списка: ошибка уже отражена
      // в AppErrorView списка — отдельный SnackBar был бы дублем и сбивал бы
      // атрибуцию (пользователь подумал бы, что не удалилось).
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final state = ref.watch(receiptsListControllerProvider);

    final body = state.when(
      loading: () => const AppLoader(),
      error: (e, _) => AppErrorView(
        message: e is Failure ? e.message : 'Не удалось загрузить чеки',
        onRetry: () =>
            ref.read(receiptsListControllerProvider.notifier).refresh(),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return const AppEmptyState(message: 'Здесь появятся ваши чеки');
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(receiptsListControllerProvider.notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.all(tokens.spaceMd),
            itemCount: data.items.length + (data.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => SizedBox(height: tokens.spaceSm),
            itemBuilder: (context, index) {
              if (index >= data.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: AppLoader(),
                );
              }
              final receipt = data.items[index];
              return ReceiptListItem(
                receipt: receipt,
                onTap: () =>
                    context.push(AppRoutes.receiptDetailPath(receipt.id)),
                onDelete: () => _delete(receipt.id),
              );
            },
          ),
        );
      },
    );

    return AppScaffold(title: 'Чеки', body: body);
  }
}
