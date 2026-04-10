import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import '../widgets/announcement_card.dart';
import '../widgets/filter_chip_bar.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/announcements_provider.dart';
import '../providers/stories_provider.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import '../widgets/college_story_bubble.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({Key? key}) : super(key: key);

  void _showAddMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned(
                bottom: 100,
                right: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildPopOption(
                      context,
                      icon: Icons.history_edu,
                      label: 'College Story',
                      onTap: () {
                        context.pop();
                        context.pushNamed(RouteNames.createStory);
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPopOption(
                      context,
                      icon: Icons.campaign_rounded,
                      label: 'Announcement',
                      onTap: () {
                        context.pop();
                        context.pushNamed(RouteNames.composeAnnouncement);
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () => context.pop(),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: curve,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(announcementsProvider);
    final stories = ref.watch(storiesProvider);
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty 
        ? user.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => context.pushNamed(RouteNames.profile),
            child: AvatarInitials(initials: initials, radius: 16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
               // Toggle Theme Logic
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: stories.isEmpty
                  ? const Center(child: Text('Not stories yet', style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      itemCount: stories.length,
                      itemBuilder: (context, index) {
                        return CollegeStoryBubble(
                          collegeName: stories[index].collegeName,
                          imageUrl: stories[index].imageUrl,
                          onTap: _dummy,
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FilterChipBar(
                categories: const ['All updates', 'Class', 'Academics', 'Sports', 'Financial'],
                onSelected: (val) {},
              ),
            ),
          ),
          posts.isEmpty
              ? const SliverFillRemaining(
                  child: EmptyStateWidget(
                    icon: Icons.notifications_off_outlined,
                    message: 'No updates from CoICT yet',
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return AnnouncementCard(
                        post: post,
                        onTap: () => context.pushNamed(
                          RouteNames.postDetail,
                          pathParameters: {'id': post.id},
                          extra: post,
                        ),
                        onLike: () => ref.read(announcementsProvider.notifier).toggleLike(post.id),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void _dummy() {}
