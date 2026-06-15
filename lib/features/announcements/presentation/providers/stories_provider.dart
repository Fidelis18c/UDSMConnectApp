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

  Future<void> refresh() async {
    state = const AsyncLoading();
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