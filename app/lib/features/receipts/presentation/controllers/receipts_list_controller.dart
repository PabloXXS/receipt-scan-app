/// Назначение: контроллер списка чеков — пагинация (offset), удаление, refresh.
///
/// Слой: presentation
/// Фича: receipts
/// Зависимости: riverpod_annotation, data/repositories/receipts_repository_impl.dart,
///   domain/entities/receipt.dart.
/// Ключевые типы: ReceiptsListState, ReceiptsListController,
///   receiptsListControllerProvider, kReceiptsPageSize.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/receipts_repository_impl.dart';
import '../../domain/entities/receipt.dart';

part 'receipts_list_controller.g.dart';

/// Размер страницы списка чеков.
const int kReceiptsPageSize = 25;

/// Снимок состояния списка: элементы, есть ли ещё, идёт ли догрузка.
class ReceiptsListState {
  const ReceiptsListState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Receipt> items;
  final bool hasMore;
  final bool isLoadingMore;

  ReceiptsListState copyWith({
    List<Receipt>? items,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      ReceiptsListState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Грузит первую страницу; умеет догружать и удалять с перезапросом.
@riverpod
class ReceiptsListController extends _$ReceiptsListController {
  @override
  Future<ReceiptsListState> build() async {
    final page = await ref
        .watch(receiptsRepositoryProvider)
        .list(limit: kReceiptsPageSize, offset: 0);
    return ReceiptsListState(
      items: page,
      hasMore: page.length == kReceiptsPageSize,
    );
  }

  /// Догружает следующую страницу (idempotent при отсутствии данных/догрузке).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final next = await ref.read(receiptsRepositoryProvider).list(
            limit: kReceiptsPageSize,
            offset: current.items.length,
          );
      state = AsyncData(ReceiptsListState(
        items: [...current.items, ...next],
        hasMore: next.length == kReceiptsPageSize,
      ));
    } catch (_) {
      // Догрузка не критична: снимаем флаг, страница останется как была.
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Pull-to-refresh: перезагрузка с начала.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Удаляет чек и перезапрашивает список с начала.
  Future<void> deleteReceipt(String id) async {
    await ref.read(receiptsRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}
