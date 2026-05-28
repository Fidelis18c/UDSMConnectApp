import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/stories_provider.dart';
import 'package:udsm_connect/features/stories/presentation/widgets/story_bubble.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/features/stories/presentation/screens/story_viewer_screen.dart';

class StoriesTray extends ConsumerWidget {
  const StoriesTray({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedStoriesAsync = ref.watch(groupedStoriesProvider);
    final isStoriesLoading = ref.watch(storiesProvider).isLoading;
    final user = ref.watch(authProvider).user;
    final isStudent = user?.isStudent ?? false;
    final canAddStories = !isStudent;

    if (groupedStoriesAsync.isEmpty && !isStoriesLoading && !canAddStories) {
      return const SizedBox.shrink();
    }

    final itemCount = groupedStoriesAsync.length + (canAddStories ? 1 : 0);

    return SizedBox(
      height: 110,
      child: isStoriesLoading && groupedStoriesAsync.isEmpty
          ? _buildSkeletonIndicator()
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (canAddStories && index == 0) {
                  return StoryBubble(
                    label: 'Add Story',
                    isViewed: true, // no gradient
                    isAddStory: true,
                    onTap: () {
                      context.pushNamed(RouteNames.createStory);
                    },
                  );
                }

                final groupIndex = canAddStories ? index - 1 : index;
                final group = groupedStoriesAsync[groupIndex];
                return StoryBubble(
                  label: group.label,
                  imageUrl: group.imageUrl,
                  isViewed: group.allViewed,
                  onTap: () {
                    // Navigate to the full screen viewer
                    context.pushNamed(
                      RouteNames.storyViewer,
                      extra: StoryViewerArgs(
                        groups: groupedStoriesAsync,
                        initialGroupIndex: groupIndex,
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSkeletonIndicator() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
