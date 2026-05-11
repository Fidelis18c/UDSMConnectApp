import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/features/announcements/data/announcements_repository.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository();
});

class AnnouncementsNotifier extends AsyncNotifier<List<Post>> {
  PostsRepository get _posts => ref.read(postsRepositoryProvider);

  @override
  Future<List<Post>> build() {
    return _posts.fetchFeed(page: 1, pageSize: 20);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _posts.fetchFeed(page: 1, pageSize: 20));
  }

  void prependLocal(Post post) {
    final current = state.value;
    if (current == null) {
      state = AsyncData([post]);
      return;
    }
    state = AsyncValue.data([post, ...current]);
  }

  Future<void> applyDetailSnapshot(Post updated) async {
    final current = state.value;
    if (current == null) return;
    final next = [
      for (final p in current)
        if (p.id == updated.id)
          p.copyWith(
            title: updated.title.isNotEmpty ? updated.title : p.title,
            text: updated.text,
            imageUrl: updated.imageUrl ?? p.imageUrl,
            likes: updated.likes,
            isLiked: updated.isLiked,
            category: updated.category.isNotEmpty ? updated.category : p.category,
          )
        else
          p,
    ];
    state = AsyncValue.data(next);
  }

  Future<void> toggleLike(String postId) async {
    final snapshot = state.value;
    if (snapshot == null) return;

    final index = snapshot.indexWhere((p) => p.id == postId);
    if (index < 0) return;

    final post = snapshot[index];
    final optimistic = post.copyWith(
      isLiked: !post.isLiked,
      likes: post.isLiked ? (post.likes - 1).clamp(0, 1 << 30) : post.likes + 1,
    );

    final optimisticList = [...snapshot];
    optimisticList[index] = optimistic;
    state = AsyncValue.data(optimisticList);

    try {
      await _posts.toggleLike(postId);
    } on DioException {
      state = AsyncValue.data(snapshot);
    }
  }
}

final announcementsProvider =
    AsyncNotifierProvider<AnnouncementsNotifier, List<Post>>(AnnouncementsNotifier.new);
