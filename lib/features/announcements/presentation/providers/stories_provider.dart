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

    // Only include stories that have a college — stories from users with no
    // college assigned are an edge case and should not appear in the tray
    // (they would otherwise group by author ID and show the person's name).
    final collegeStories = stories.where((s) => s.college != null).toList();
    if (collegeStories.isEmpty) return <StoryGroup>[];

    final Map<String, List<Story>> map = {};
    for (final s in collegeStories) {
      map.putIfAbsent(s.college!.id, () => []).add(s);
    }

    final List<StoryGroup> groups = map.entries.map((e) {
      // sort stories inside group ascending by time
      e.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final first = e.value.first;
      // Label is always the college short name
      final label = first.college!.shortName;
      final bool allViewed = e.value.every((st) => st.hasViewed);

      // Use the most recent story that has a media URL for the bubble thumbnail
      final String? groupImageUrl = e.value
          .lastWhere((s) => s.media?.url != null, orElse: () => first)
          .media
          ?.url;

      return StoryGroup(
        groupId: e.key,
        label: label,
        imageUrl: groupImageUrl,
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
