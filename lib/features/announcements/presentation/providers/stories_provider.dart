import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/story.dart';
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

class StoryGroup {
  final String groupId;
  final String label;
  final String? imageUrl;
  final bool allViewed;
  final List<Story> stories;

  StoryGroup({
    required this.groupId,
    required this.label,
    this.imageUrl,
    required this.allViewed,
    required this.stories,
  });
}

final groupedStoriesProvider = Provider<List<StoryGroup>>((ref) {
  final asyncStories = ref.watch(storiesProvider);

  return asyncStories.whenData((stories) {
    if (stories.isEmpty) return <StoryGroup>[];

    final Map<String, List<Story>> map = {};
    for (final s in stories) {
      final key = s.college?.id ?? s.author.id;
      map.putIfAbsent(key, () => []).add(s);
    }

    final List<StoryGroup> groups = map.entries.map((e) {
      // sort stories inside group ascending by time
      e.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final first = e.value.first;
      final label = first.college?.shortName ?? first.author.fullName;
      final bool allViewed = e.value.every((st) => st.hasViewed);

      return StoryGroup(
        groupId: e.key,
        label: label,
        imageUrl: first.media?.url,
        allViewed: allViewed,
        stories: e.value,
      );
    }).toList();

    // sort groups: unviewed first, then by latest story
    groups.sort((a, b) {
      if (a.allViewed && !b.allViewed) return 1;
      if (!a.allViewed && b.allViewed) return -1;

      // both same viewed status, sort by newest story
      final aLatest = a.stories.last.createdAt;
      final bLatest = b.stories.last.createdAt;
      return bLatest.compareTo(aLatest);
    });

    return groups;
  }).value ?? [];
});
