import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../data/models/lost_found.dart';
import '../../data/repositories/lost_found_repository.dart';

final lostFoundRepositoryProvider = Provider((ref) => LostFoundRepository());

final lostFoundCategoriesProvider = FutureProvider<List<LostFoundCategory>>((ref) async {
  return ref.watch(lostFoundRepositoryProvider).getCategories();
});

final lostFoundItemsProvider = StateNotifierProvider<LostFoundNotifier, AsyncValue<List<LostFoundItem>>>((ref) {
  return LostFoundNotifier(ref.watch(lostFoundRepositoryProvider));
});

class LostFoundNotifier extends StateNotifier<AsyncValue<List<LostFoundItem>>> {
  final LostFoundRepository _repository;
  
  LostFoundNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchItems();
  }

  Future<void> fetchItems({
    String? type,
    String? categoryId,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getItems(
        type: type,
        categoryId: categoryId,
        search: search,
      );
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createItem({
    required String title,
    required String description,
    required String type,
    String? categoryId,
    String? location,
    DateTime? dateLostFound,
    bool isAnonymous = false,
    List<String>? mediaIds,
  }) async {
    try {
      await _repository.createItem(
        title: title,
        description: description,
        type: type,
        categoryId: categoryId,
        location: location,
        dateLostFound: dateLostFound,
        isAnonymous: isAnonymous,
        mediaIds: mediaIds,
      );
      fetchItems();
      return true;
    } catch (e) {
      return false;
    }
  }
}
