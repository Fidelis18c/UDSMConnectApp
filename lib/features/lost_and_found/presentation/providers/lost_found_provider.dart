import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:state_notifier/state_notifier.dart';
import '../../data/models/lost_found.dart';
import '../../data/repositories/lost_found_repository.dart';

final lostFoundRepositoryProvider = Provider((ref) => LostFoundRepository());

final lostFoundCategoriesProvider = FutureProvider<List<LostFoundCategory>>((ref) async {
  return ref.watch(lostFoundRepositoryProvider).getCategories();
});

class SelectedLostFoundCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final selectedLostFoundCategoryIdProvider = NotifierProvider<SelectedLostFoundCategoryNotifier, String?>(() {
  return SelectedLostFoundCategoryNotifier();
});

final lostFoundItemsProvider = StateNotifierProvider<LostFoundNotifier, AsyncValue<List<LostFoundItem>>>((ref) {
  final repo = ref.watch(lostFoundRepositoryProvider);
  final categoryId = ref.watch(selectedLostFoundCategoryIdProvider);
  return LostFoundNotifier(repo, categoryId);
});

class LostFoundNotifier extends StateNotifier<AsyncValue<List<LostFoundItem>>> {
  final LostFoundRepository _repository;
  final String? _categoryId;
  
  LostFoundNotifier(this._repository, this._categoryId) : super(const AsyncValue.loading()) {
    fetchItems(categoryId: _categoryId);
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
      print('DEBUG: Fetched ${items.length} lost/found items');
      state = AsyncValue.data(items);
    } catch (e, stack) {
      print('DEBUG: Error fetching lost/found: $e');
      print(stack);
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
    String? contactInfo,
    List<String>? mediaIds,
  }) async {
    try {
      print('DEBUG: Creating LostFound item: $title');
      await _repository.createItem(
        title: title,
        description: description,
        type: type,
        categoryId: categoryId,
        location: location,
        dateLostFound: dateLostFound,
        isAnonymous: isAnonymous,
        contactInfo: contactInfo,
        mediaIds: mediaIds,
      );
      print('DEBUG: LostFound item created successfully');
      fetchItems();
      return true;
    } catch (e, stack) {
      print('DEBUG: Failed to create LostFound item: $e');
      print(stack);
      return false;
    }
  }
}
