import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/core/widgets/news_post_card.dart';
import 'package:udsm_connect/core/widgets/post_menu.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/profile/presentation/providers/user_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import 'package:udsm_connect/core/theme/theme_provider.dart';
import 'package:udsm_connect/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/core/providers/scroll_visibility_provider.dart';

class NewsFeedScreen extends ConsumerWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(announcementsProvider);
    final authUser = ref.watch(authProvider).user;
    final canPostNews = authUser?.canPostNews ?? false;
    final user = ref.watch(userProvider);
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).join().toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: !canPostNews ? null : Consumer(
        builder: (context, ref, child) {
          final isVisible = ref.watch(scrollVisibilityProvider);
          return AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: isVisible ? Offset.zero : const Offset(0, 2.5),
            curve: Curves.fastOutSlowIn,
            child: child!,
          );
        },
        child: FloatingActionButton(
          elevation: 2,
          onPressed: () => context.pushNamed(RouteNames.composeAnnouncement),
          child: const PhosphorIcon(PhosphorIconsBold.plus, size: 26),
        ),
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
                          child: AvatarInitials(
                            initials: initials,
                            imageUrl: user.profilePic,
                            radius: 18,
                          ),
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
                      width: 96,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Consumer(
                            builder: (context, ref, _) {
                              final unreadAsync = ref.watch(unreadCountProvider);
                              final unread = unreadAsync.value ?? 0;
                              final hasNew = unread > 0;
                              return IconButton(
                                icon: PhosphorIcon(
                                  hasNew
                                      ? PhosphorIconsFill.bell
                                      : PhosphorIconsRegular.bell,
                                  size: 24,
                                  // Lights up blue when something new arrived.
                                  color: hasNew
                                      ? AppColors.primary
                                      : Theme.of(context).iconTheme.color,
                                ),
                                onPressed: () => context
                                    .pushNamed(RouteNames.notifications),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              return PopupMenuButton<String>(
                                icon: PhosphorIcon(
                                  PhosphorIconsRegular.gearSix,
                                  size: 24,
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                color: Theme.of(context).colorScheme.surface,
                                onSelected: (value) async {
                                  if (value == 'theme') {
                                    ref.read(themeProvider.notifier).toggleTheme();
                                  } else if (value == 'logout') {
                                    await ref.read(authProvider.notifier).logout();
                                    if (context.mounted) {
                                      context.goNamed(RouteNames.login);
                                    }
                                  }
                                },
                                itemBuilder: (context) {
                                  final isDark =
                                      ref.read(themeProvider) == ThemeMode.dark;
                                  final itemColor =
                                      Theme.of(context).colorScheme.onSurface;
                                  return [
                                    PopupMenuItem(
                                      value: 'theme',
                                      child: Row(
                                        children: [
                                          PhosphorIcon(
                                            isDark
                                                ? PhosphorIconsRegular.sun
                                                : PhosphorIconsRegular.moon,
                                            color: itemColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            isDark ? 'Light mode' : 'Dark mode',
                                            style: TextStyle(color: itemColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          PhosphorIcon(
                                            PhosphorIconsRegular.signOut,
                                            color: itemColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Logout',
                                              style: TextStyle(color: itemColor)),
                                        ],
                                      ),
                                    ),
                                  ];
                                },
                              );
                            },
                          ),
                        ],
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
                          onLike: () =>
                              ref.read(announcementsProvider.notifier).toggleLike(post.id),
                          onMenuTap: () => showPostMenu(context, ref, post),
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
