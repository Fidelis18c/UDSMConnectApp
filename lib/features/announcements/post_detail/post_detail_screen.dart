import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/core/formatting/relative_time.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/comments/presentation/widgets/comment_section.dart';
import 'package:udsm_connect/features/comments/presentation/providers/comments_provider.dart';

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

  Future<void> _share(Post display) async {
    final snippet =
        '${display.title.isNotEmpty ? '${display.title}\n\n' : ''}${display.text}'.trim();
    if (snippet.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: snippet));
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            visualDensity: VisualDensity.compact,
                            icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24),
                          ),
                          AvatarInitials(
                            initials: display.authorName.isNotEmpty
                                ? display.authorName.substring(0, 1).toUpperCase()
                                : '?',
                            imageUrl: display.authorProfilePic,
                            radius: 18,
                          ),
                        ],
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
                        onPressed: () {},
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
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
                          radius: 24,
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
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: PhosphorIcon(
                                      PhosphorIconsRegular.dotsThreeVertical,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () {},
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
                            color: AppColors.textSecondary,
                            height: 1.55,
                          ),
                    ),
                    if (display.imageUrl != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.network(
                            display.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
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
                    ],
                    // Twitter-like metadata line
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                                          color: Colors.white,
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
                                      color: Colors.white,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            onPressed: () {}, // Handled by comment section below functionally
                            icon: const PhosphorIcon(PhosphorIconsRegular.chatCircle, size: 22, color: AppColors.textHint),
                          ),
                          IconButton(
                            onPressed: () => ref
                                .read(announcementsProvider.notifier)
                                .toggleLike(display.id),
                            icon: PhosphorIcon(
                              display.isLiked ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                              size: 22,
                              color: display.isLiked ? Colors.pink : AppColors.textHint,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _share(display),
                            icon: const PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 22, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    
                    const SizedBox(height: 24),
                    CommentSection(
                      targetId: display.id,
                      targetType: 'ANNOUNCEMENT',
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
