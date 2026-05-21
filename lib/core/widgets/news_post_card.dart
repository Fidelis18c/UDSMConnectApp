import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'package:udsm_connect/core/formatting/relative_time.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';

/// Feed card for a news / social post — reusable across NEWS, previews, etc.
class NewsPostCard extends StatelessWidget {
  const NewsPostCard({
    super.key,
    required this.post,
    required this.onOpen,
    required this.onLike,
    this.onReplyTap,
    this.replyCount = 0,
    this.onMenuTap,
  });

  final Post post;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback? onReplyTap;
  final VoidCallback? onMenuTap;

  /// Shown beside the comment icon until the API exposes `commentCount` on [`Post`].
  final int replyCount;

  Future<void> _share(BuildContext context) async {
    final snippet =
        '${post.title.isNotEmpty ? '${post.title}\n' : ''}${post.text}'.trim();
    if (snippet.isEmpty) return;
    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    await SharePlus.instance
        .share(ShareParams(text: snippet, sharePositionOrigin: origin));
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141414)
        : Theme.of(context).colorScheme.surface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AvatarInitials(
                      initials: post.authorName.isNotEmpty
                          ? post.authorName.substring(0, 1).toUpperCase()
                          : '?',
                      imageUrl: post.authorProfilePic,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  post.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                        height: 1.15,
                                      ),
                                ),
                              ),
                              Text(
                                formatShortRelative(post.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                icon: PhosphorIcon(
                                  PhosphorIconsRegular.dotsThreeVertical,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed:
                                    onMenuTap ?? () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (post.isPinned) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pinned',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.link,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
                if (post.title.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                  ),
                ],
                if (post.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post.text,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                  ),
                ],
                if (post.imageUrl != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1.3,
                        child: Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF1A1A1A),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF252525),
                            alignment: Alignment.center,
                            child: PhosphorIcon(
                              PhosphorIconsRegular.imageBroken,
                              size: 40,
                              color: AppColors.textHint,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _IconCountTap(
                      icon: post.isLiked
                          ? PhosphorIconsFill.thumbsUp
                          : PhosphorIconsRegular.thumbsUp,
                      iconFill: post.isLiked ? 1.0 : null,
                      count: post.likes,
                      color: post.isLiked ? AppColors.link : AppColors.textSecondary,
                      onTap: onLike,
                    ),
                    const SizedBox(width: 16),
                    _IconCountTap(
                      icon: PhosphorIconsRegular.chatCircleDots,
                      count: replyCount,
                      onTap: onReplyTap ?? () {},
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _share(context),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: PhosphorIcon(
                          PhosphorIconsRegular.shareFat,
                          size: 22,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCountTap extends StatelessWidget {
  const _IconCountTap({
    required this.icon,
    required this.count,
    required this.onTap,
    this.iconFill,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final double? iconFill;
  final int count;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              icon,
              size: 18,
              color: color,
              fill: iconFill ?? 0.0,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
