import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/item_category.dart';

part 'item_categories_repository.g.dart';

@riverpod
ItemCategoriesRepository itemCategoriesRepository(
  ItemCategoriesRepositoryRef ref,
) {
  return ItemCategoriesRepository();
}

class ItemCategoriesRepository {
  Future<List<ItemCategory>> getAllCategories() async {
    final client = Supabase.instance.client;

    final response = await client
        .from('categories')
        .select()
        .eq('is_deleted', false)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((json) => ItemCategory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ItemCategory> createCategory(String name) async {
    final client = Supabase.instance.client;

    final response = await client
        .from('categories')
        .insert({'name': name})
        .select()
        .single();

    return ItemCategory.fromJson(response as Map<String, dynamic>);
  }
}

