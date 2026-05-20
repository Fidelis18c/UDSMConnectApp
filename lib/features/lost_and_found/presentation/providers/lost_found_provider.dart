import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/lost_found.dart';
import '../../data/repositories/lost_found_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final lostFoundRepositoryProvider = Provider((ref) => LostFoundRepository());

// ── Categories ────────────────────────────────────────────────────────────────

final lostFoundCategoriesProvider = FutureProvider<List<LostFoundCategory>>((ref) async {
  return ref.watch(lostFoundRepositoryProvider).getCategories();
});

// ── Category filter ──────────────────────────────────────────────────────────

class SelectedLostFoundCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final selectedLostFoundCategoryIdProvider =
    NotifierProvider<SelectedLostFoundCategoryNotifier, String?>(
        SelectedLostFoundCategoryNotifier.new);

// ── Type filter: null = All, "LOST", "FOUND" ─────────────────────────────────

class TypeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final typeFilterProvider =
    NotifierProvider<TypeFilterNotifier, String?>(TypeFilterNotifier.new);

// ── Search query ──────────────────────────────────────────────────────────────

class LFSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String val) => state = val;
}

final lfSearchQueryProvider =
    NotifierProvider<LFSearchQueryNotifier, String>(LFSearchQueryNotifier.new);

// ── Main feed notifier (Riverpod 3.x AsyncNotifier) ──────────────────────────

class LostFoundNotifier extends AsyncNotifier<List<LostFoundItem>> {
  @override
  Future<List<LostFoundItem>> build() async {
    final categoryId = ref.watch(selectedLostFoundCategoryIdProvider);
    return _fetch(categoryId: categoryId);
  }

  Future<List<LostFoundItem>> _fetch({String? categoryId}) async {
    return ref.read(lostFoundRepositoryProvider).getItems(
          categoryId: categoryId,
        );
  }

  Future<void> refresh() async {
    final categoryId = ref.read(selectedLostFoundCategoryIdProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(categoryId: categoryId));
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
      await ref.read(lostFoundRepositoryProvider).createItem(
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
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> updates) async {
    try {
      await ref.read(lostFoundRepositoryProvider).updateItem(id, updates);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveItem(String id) async {
    try {
      await ref.read(lostFoundRepositoryProvider).resolveItem(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await ref.read(lostFoundRepositoryProvider).deleteItem(id);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final lostFoundItemsProvider =
    AsyncNotifierProvider<LostFoundNotifier, List<LostFoundItem>>(
        LostFoundNotifier.new);

// ── Filtered list (client-side: search + type) ────────────────────────────────

final filteredLostFoundProvider = Provider<AsyncValue<List<LostFoundItem>>>((ref) {
  final all = ref.watch(lostFoundItemsProvider);
  final query = ref.watch(lfSearchQueryProvider).toLowerCase().trim();
  final type = ref.watch(typeFilterProvider);

  return all.whenData((items) {
    var result = items;
    if (type != null) {
      result = result.where((i) => i.type == type).toList();
    }
    if (query.isNotEmpty) {
      result = result
          .where((i) =>
              i.title.toLowerCase().contains(query) ||
              (i.location?.toLowerCase().contains(query) ?? false))
          .toList();
    }
    return result;
  });
});
