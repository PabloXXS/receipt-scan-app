import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/item_category.dart';
import '../repositories/item_categories_repository.dart';

part 'item_categories_provider.g.dart';

@riverpod
class ItemCategories extends _$ItemCategories {
  @override
  FutureOr<List<ItemCategory>> build() async {
    return ref.read(itemCategoriesRepositoryProvider).getAllCategories();
  }

  Future<void> createCategory(String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(itemCategoriesRepositoryProvider).createCategory(name);
      return ref.read(itemCategoriesRepositoryProvider).getAllCategories();
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

