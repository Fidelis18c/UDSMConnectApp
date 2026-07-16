import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/features/comments/data/models/comment.dart';
import 'package:udsm_connect/features/comments/presentation/providers/comments_provider.dart';
import 'package:udsm_connect/features/comments/presentation/widgets/comment_section.dart';

/// Dedicated page for writing a reply to someone's comment.
class ReplyScreen extends ConsumerWidget {
  final String targetId;
  final String targetType;
  final Comment comment;

  const ReplyScreen({
    super.key,
    required this.targetId,
    required this.comment,
    this.targetType = 'ANNOUNCEMENT',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CommentsParams(targetId: targetId, targetType: targetType);
    final cleanAuthorName = comment.authorName.split('@')[0].trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text('Reply'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The comment being replied to
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvatarInitials(
                          initials: cleanAuthorName.isNotEmpty
                              ? cleanAuthorName[0].toUpperCase()
                              : '?',
                          imageUrl: comment.authorProfilePic,
                          radius: 16,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cleanAuthorName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.4,
                                ),
                              ),
                              if (comment.imageUrl != null) ...[
                                SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedNetworkImage(
                                    imageUrl: comment.imageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    placeholderFadeInDuration: Duration.zero,
                                    errorWidget: (_, __, ___) =>
                                        SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Replying to ',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textHint),
                        ),
                        Text(
                          cleanAuthorName,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: NewCommentBox(
                params: params,
                parentId: comment.id,
                hintOverride: 'Post your reply',
                onSuccess: () => context.pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
