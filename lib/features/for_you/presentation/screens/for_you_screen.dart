import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/widgets/news_post_card.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:udsm_connect/navigation/route_names.dart';

/// Personalised / class-scoped content (filtered from the main feed).
class ForYouScreen extends ConsumerWidget {
  const ForYouScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(announcementsProvider);
    final user = ref.watch(authProvider).user;
    final isStudent = user?.isStudent ?? false;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('For you'),
      ),
      floatingActionButton: isStudent ? null : FloatingActionButton(
        elevation: 2,
        onPressed: () => context.pushNamed(
          RouteNames.composeAnnouncement,
          extra: {
            'title': 'Class Announcement',
            'bodyHint': 'Write your class announcement here...',
            'postType': 'NOTICE',
          },
        ),
        child: const PhosphorIcon(PhosphorIconsBold.plus, size: 26),
      ),
      body: RefreshIndicator.adaptive(
        color: AppColors.primary,
        onRefresh: () => ref.read(announcementsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            asyncPosts.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $err')),
              ),
              data: (allPosts) {
                final posts = allPosts
                    .where((p) => p.category == 'NOTICE')
                    .toList();

                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: PhosphorIconsRegular.sparkle,
                      message: 'No class announcements yet.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: posts.length,
                      (context, index) {
                        final post = posts[index];
                        return NewsPostCard(
                          post: post,
                          replyCount: post.commentCount,
                          onOpen: () => context.pushNamed(
                            RouteNames.postDetail,
                            pathParameters: {'id': post.id},
                            extra: post,
                          ),
                          onReplyTap: () => context.pushNamed(
                            RouteNames.postDetail,
                            pathParameters: {'id': post.id},
                            extra: post,
                          ),
                          onLike: () => ref
                              .read(announcementsProvider.notifier)
                              .toggleLike(post.id),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
