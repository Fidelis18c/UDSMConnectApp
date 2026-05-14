import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/widgets/news_post_card.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';
import 'package:udsm_connect/navigation/route_names.dart';

class NewsFeedScreen extends ConsumerWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(announcementsProvider);
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        elevation: 2,
        onPressed: () => context.pushNamed(RouteNames.composeAnnouncement),
        child: const PhosphorIcon(PhosphorIconsBold.plus, size: 26),
      ),
      body: RefreshIndicator.adaptive(
        color: AppColors.primary,
        onRefresh: () => ref.read(announcementsProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 56,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => context.pushNamed(RouteNames.profile),
                          child: AvatarInitials(initials: initials, radius: 18),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'NEWS',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.gearSix,
                          size: 26,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.warningCircle,
                        size: 42,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load posts',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => ref.read(announcementsProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (allPosts) {
                final posts = allPosts.where((p) => p.category != 'NOTICE' && p.category != 'ALERT').toList();
                if (posts.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: PhosphorIconsRegular.newspaper,
                      message: 'No posts yet. Pull down to refresh.',
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
                          onOpen: () => context.pushNamed(
                            RouteNames.postDetail,
                            pathParameters: {'id': post.id},
                            extra: post,
                          ),
                          onLike: () =>
                              ref.read(announcementsProvider.notifier).toggleLike(post.id),
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
