import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/story.dart';
import 'package:udsm_connect/core/utils/story_grouping.dart';
import 'package:udsm_connect/features/stories/data/repositories/story_repository.dart';

class StoriesNotifier extends AsyncNotifier<List<Story>> {
  @override
  Future<List<Story>> build() async {
    return StoryRepository().fetchStories();
  }

  Future<void> markViewed(String storyId) async {
    await StoryRepository().markViewed(storyId);
    if (state.value != null) {
      state = AsyncData(state.value!.map((s) {
        if (s.id == storyId) {
          return s.copyWith(hasViewed: true);
        }
        return s;
      }).toList());
    }
  }

  /// Optimistic like toggle; rolls back on failure.
  Future<void> toggleLike(String storyId) async {
    final current = state.value;
    if (current == null) return;

    Story? story;
    for (final s in current) {
      if (s.id == storyId) {
        story = s;
        break;
      }
    }
    if (story == null) return;

    final nextLiked = !story.isLiked;
    final nextCount = (story.likeCount + (nextLiked ? 1 : -1)).clamp(0, 1 << 30);

    state = AsyncData(current.map((s) {
      if (s.id == storyId) {
        return s.copyWith(isLiked: nextLiked, likeCount: nextCount);
      }
      return s;
    }).toList());

    try {
      final isLiked = await StoryRepository().toggleLike(storyId);
      final latest = state.value ?? current;
      state = AsyncData(latest.map((s) {
        if (s.id != storyId) return s;
        if (s.isLiked == isLiked) return s;
        final count = (s.likeCount + (isLiked ? 1 : -1)).clamp(0, 1 << 30);
        return s.copyWith(isLiked: isLiked, likeCount: count);
      }).toList());
    } catch (_) {
      state = AsyncData(current);
    }
  }

  void updateCommentCount(String storyId, int delta) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.map((s) {
      if (s.id == storyId) {
        return s.copyWith(
          commentCount: (s.commentCount + delta).clamp(0, 1 << 30),
        );
      }
      return s;
    }).toList());
  }

  Future<void> refresh() async {
    // Keep tray visible during refresh for smoother pull-to-refresh.
    state = await AsyncValue.guard(() => StoryRepository().fetchStories());
  }
}

final storiesProvider = AsyncNotifierProvider<StoriesNotifier, List<Story>>(() {
  return StoriesNotifier();
});

final groupedStoriesProvider = Provider<List<StoryGroup>>((ref) {
  final asyncStories = ref.watch(storiesProvider);
  return asyncStories.whenData(groupStoriesByCollege).value ?? [];
});
