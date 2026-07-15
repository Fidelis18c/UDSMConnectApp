import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/core/formatting/relative_time.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/utils/post_share.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/core/widgets/full_screen_image_viewer.dart';

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
    Rect? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(Offset.zero) & box.size;
    }
    await PostShare.sharePost(
      postId: post.id,
      title: post.title,
      text: post.text,
      sharePositionOrigin: origin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF141414)
        : Theme.of(context).colorScheme.surface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
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
                          radius: 16,
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
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
                                        if (post.authorRole != null) ...[
                                          const SizedBox(width: 6),
                                          _RoleChip(role: post.authorRole!),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatShortRelative(post.timestamp),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontWeight: FontWeight.w700,
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
                                      PhosphorIconsBold.dotsThreeVertical,
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.onSurface,
                                    ),
                                    onPressed: onMenuTap ?? () {},
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pinned',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      _ExpandableText(text: post.text),
                    ],
                  ],
                ),
              ),
              if (post.imageUrl != null) ...[
                const SizedBox(height: 8),
                // Twitter-style frame: the image always fills the card width
                // at its natural aspect ratio; only very tall images
                // (screenshots) hit the height cap and get cropped.
                // Tapping the image opens it full-screen; tapping anywhere
                // else on the card opens the post.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GestureDetector(
                    onTap: () => openFullScreenImage(context, post.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.width * 1.1,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: post.imageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholderFadeInDuration: Duration.zero,
                          // Decode at screen width instead of the full upload size.
                          memCacheWidth: (MediaQuery.of(context).size.width *
                                  MediaQuery.of(context).devicePixelRatio)
                              .round(),
                          progressIndicatorBuilder: (context, url, progress) =>
                              AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              color: const Color(0xFF1A1A1A),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    value: progress.progress,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            debugPrint('IMAGE LOAD ERROR url=$url err=$error');
                            return AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: const Color(0xFF252525),
                                alignment: Alignment.center,
                                child: PhosphorIcon(
                                  PhosphorIconsRegular.imageBroken,
                                  size: 40,
                                  color: AppColors.textHint,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Builder(builder: (context) {
                final actionColor =
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondary
                        : Colors.black;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                  child: Row(
                    children: [
                      _IconCountTap(
                        icon: post.isLiked
                            ? PhosphorIconsFill.thumbsUp
                            : PhosphorIconsRegular.thumbsUp,
                        iconFill: post.isLiked ? 1.0 : null,
                        count: post.likes,
                        color: post.isLiked ? AppColors.link : actionColor,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 16),
                      _IconCountTap(
                        icon: PhosphorIconsRegular.chatCircleDots,
                        count: replyCount,
                        color: actionColor,
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
                            color: actionColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
        ),
      ],
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
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final String role;

  /// Ordered most-specific first so e.g. "class representative" wins over loose matches.
  static const _rules = <(String match, String label, Color color)>[
    ('super admin', 'Admin', Color(0xFF37474F)),
    ('admin', 'Admin', Color(0xFF37474F)),
    ('class representative', 'CR', Color(0xFF1565C0)),
    ('class rep', 'CR', Color(0xFF1565C0)),
    ('daruso', 'DARUSO', Color(0xFF1B5E20)),
    ('college rep', 'College', Color(0xFF1B5E20)),
    ('college leader', 'College', Color(0xFF1B5E20)),
    ('lecturer', 'Lecturer', Color(0xFF4A148C)),
    ('staff', 'Staff', Color(0xFF6A1B9A)),
    ('sports', 'Sports', Color(0xFFE65100)),
  ];

  static (String, Color)? resolve(String role) {
    final key = role.toLowerCase().replaceAll('_', ' ').trim();
    if (key == 'cr') return ('CR', const Color(0xFF1565C0));
    if (key == 'student' || key.isEmpty) return null;
    for (final rule in _rules) {
      if (key == rule.$1 || key.contains(rule.$1)) {
        return (rule.$2, rule.$3);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final match = resolve(role);
    if (match == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: match.$2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        match.$1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const int _maxLines = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
          height: 1.45,
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _maxLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : _maxLines,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: style,
            ),
            if (overflows) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show less' : 'Show more',
                  style: const TextStyle(
                    color: AppColors.link,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
