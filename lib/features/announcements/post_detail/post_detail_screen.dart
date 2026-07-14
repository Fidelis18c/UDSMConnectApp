import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/core/formatting/relative_time.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/utils/post_share.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/full_screen_image_viewer.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/comments/presentation/widgets/comment_section.dart';
import 'package:udsm_connect/features/comments/presentation/providers/comments_provider.dart';
import 'package:udsm_connect/navigation/route_names.dart';
import 'package:udsm_connect/core/theme/theme_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  /// Server id from the URL (`/announcements/:id`).
  final String announcementId;

  /// When opening from the feed, pass the list item for instant paint.
  final Post? prefetchPost;

  const PostDetailScreen({
    super.key,
    required this.announcementId,
    this.prefetchPost,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _remote;
  bool _loadFinished = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    try {
      final repo = ref.read(postsRepositoryProvider);
      final full = await repo.fetchDetail(widget.announcementId);
      if (!mounted) return;
      setState(() {
        _remote = full;
        _loadFinished = true;
        _loadFailed = false;
      });
      await ref.read(announcementsProvider.notifier).applyDetailSnapshot(full);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFinished = true;
        _loadFailed = true;
      });
    }
  }

  Post? _resolveDisplay() {
    final listed = ref.watch(announcementsProvider).value;
    if (listed != null) {
      for (final p in listed) {
        if (p.id == widget.announcementId) return p;
      }
    }
    if (_remote != null) return _remote;
    return widget.prefetchPost;
  }

  void _showPostMenu(Post display) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwner = currentUserId != null && currentUserId == display.authorId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 22),
              title: const Text('Share post'),
              onTap: () {
                Navigator.pop(sheetContext);
                _share(display);
              },
            ),
            if (isOwner)
              ListTile(
                leading: PhosphorIcon(
                  PhosphorIconsRegular.trash,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                title: Text(
                  'Delete post',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(display);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Post display) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will permanently remove the post.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(postsRepositoryProvider).deletePost(display.id);
      await ref.read(announcementsProvider.notifier).refresh();
      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Post deleted.')));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to delete post. Try again.')),
      );
    }
  }

  Future<void> _share(Post display) async {
    await PostShare.sharePost(
      postId: display.id,
      title: display.title,
      text: display.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final display = _resolveDisplay();

    if (display == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24),
            onPressed: () => context.pop(),
          ),
          title: const Text('NEWS'),
        ),
        body: Center(
          child: _loadFinished && _loadFailed && widget.prefetchPost == null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.warningCircle,
                        size: 40,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load this announcement',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _loadFinished = false;
                            _loadFailed = false;
                          });
                          _loadDetail();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator.adaptive(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        visualDensity: VisualDensity.compact,
                        icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24),
                      ),
                    ),
                  ),
                  Text(
                    'NEWS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () {
                          final isDark =
                              ref.read(themeProvider) == ThemeMode.dark;
                          ref.read(themeProvider.notifier).toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isDark
                                  ? 'Switched to light mode'
                                  : 'Switched to dark mode'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        visualDensity: VisualDensity.compact,
                        icon: PhosphorIcon(
                          PhosphorIconsRegular.gearSix,
                          size: 24,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AvatarInitials(
                                initials: display.authorName.isNotEmpty
                                    ? display.authorName.substring(0, 1).toUpperCase()
                                    : '?',
                                imageUrl: display.authorProfilePic,
                                radius: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            display.authorName,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          formatShortRelative(display.timestamp),
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: PhosphorIcon(
                                            PhosphorIconsBold.dotsThreeVertical,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          onPressed: () => _showPostMenu(display),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      display.subtitleHandle,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.textHint,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (display.title.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              display.title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            display.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w500,
                                  height: 1.55,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (display.imageUrl != null) ...[
                      const SizedBox(height: 8),
                      // Twitter-style frame: image fills the width at its
                      // natural ratio; only very tall images hit the height
                      // cap and get cropped. Tap opens it full-screen.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () =>
                              openFullScreenImage(context, display.imageUrl!),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.width * 1.1,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: display.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholderFadeInDuration: Duration.zero,
                                memCacheWidth: (MediaQuery.of(context).size.width *
                                        MediaQuery.of(context).devicePixelRatio)
                                    .round(),
                                errorWidget: (context, url, error) => AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    color: const Color(0xFF252525),
                                    alignment: Alignment.center,
                                    child: PhosphorIcon(
                                      PhosphorIconsRegular.imageBroken,
                                      size: 56,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Twitter-like metadata line
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${formatDetailFooterTime(display.timestamp)} · ${formatDetailFooterDate(display.timestamp)}',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.textHint,
                                    fontSize: 14,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppColors.divider),
                          // Twitter-like Stats line
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Consumer(
                                  builder: (context, ref, child) {
                                    final params = CommentsParams(
                                      targetId: display.id,
                                      targetType: 'ANNOUNCEMENT',
                                    );
                                    final asyncComments = ref.watch(commentsQueryProvider(params));
                                    int commentsCount = 0;
                                    if (asyncComments.hasValue && asyncComments.value != null) {
                                      commentsCount = asyncComments.value!.fold(
                                          0, (sum, c) => sum + 1 + c.replyCount);
                                    }
                                    return Row(
                                      children: [
                                        Text(
                                          '$commentsCount',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Comments',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.textHint,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Text(
                                      '${display.likes}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Likes',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textHint,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.divider),
                          // X-style Action Bar
                          Builder(builder: (context) {
                            final actionColor =
                                Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.textHint
                                    : Colors.black;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  IconButton(
                                    onPressed: () => context.pushNamed(
                                      RouteNames.postComments,
                                      pathParameters: {'id': display.id},
                                    ),
                                    icon: PhosphorIcon(PhosphorIconsRegular.chatCircle, size: 22, color: actionColor),
                                  ),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(announcementsProvider.notifier)
                                        .toggleLike(display.id),
                                    icon: PhosphorIcon(
                                      display.isLiked ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                                      size: 22,
                                      color: display.isLiked ? Colors.pink : actionColor,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _share(display),
                                    icon: PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 22, color: actionColor),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 24),
                          CommentSection(
                            targetId: display.id,
                            targetType: 'ANNOUNCEMENT',
                            showInput: false,
                            onReplyTap: (comment) => context.pushNamed(
                              RouteNames.commentReply,
                              pathParameters: {'id': display.id},
                              extra: comment,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
