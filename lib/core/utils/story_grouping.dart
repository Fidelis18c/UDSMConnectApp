import 'package:udsm_connect/core/models/story.dart';

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

List<StoryGroup> groupStoriesByCollege(List<Story> stories) {
  if (stories.isEmpty) return [];

  final collegeStories = stories.where((s) => s.college != null).toList();
  if (collegeStories.isEmpty) return [];

  final map = <String, List<Story>>{};
  for (final story in collegeStories) {
    map.putIfAbsent(story.college!.id, () => []).add(story);
  }

  final groups = map.entries.map((entry) {
    entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final first = entry.value.first;
    final label = first.college!.shortName;
    final allViewed = entry.value.every((s) => s.hasViewed);
    final imageUrl = entry.value
        .lastWhere((s) => s.media?.url != null, orElse: () => first)
        .media
        ?.url;

    return StoryGroup(
      groupId: entry.key,
      label: label,
      imageUrl: imageUrl,
      allViewed: allViewed,
      stories: entry.value,
    );
  }).toList();

  groups.sort((a, b) {
    if (a.allViewed && !b.allViewed) return 1;
    if (!a.allViewed && b.allViewed) return -1;
    return b.stories.last.createdAt.compareTo(a.stories.last.createdAt);
  });

  return groups;
}

/// Finds the college story group index containing [storyId].
int? findStoryGroupIndex(List<StoryGroup> groups, String storyId) {
  for (var i = 0; i < groups.length; i++) {
    if (groups[i].stories.any((s) => s.id == storyId)) return i;
  }
  return null;
}

class StoryViewerArgs {
  final List<StoryGroup> groups;
  final int initialGroupIndex;

  StoryViewerArgs({required this.groups, required this.initialGroupIndex});
}

StoryViewerArgs buildStoryViewerArgs(List<StoryGroup> groups, String storyId) {
  final index = findStoryGroupIndex(groups, storyId) ?? 0;
  return StoryViewerArgs(groups: groups, initialGroupIndex: index);
}