import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/features/comments/presentation/providers/comments_provider.dart';
import 'package:udsm_connect/features/comments/presentation/widgets/comment_section.dart';
import 'package:udsm_connect/navigation/route_names.dart';

/// Full-screen comments page opened from the comment icon on a post.
class CommentsScreen extends ConsumerWidget {
  final String targetId;
  final String targetType;

  const CommentsScreen({
    super.key,
    required this.targetId,
    this.targetType = 'ANNOUNCEMENT',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CommentsParams(targetId: targetId, targetType: targetType);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft, size: 24),
          onPressed: () => context.pop(),
        ),
        title: const Text('Comments'),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: CommentSection(
                  targetId: targetId,
                  targetType: targetType,
                  showInput: false,
                  onReplyTap: (comment) => context.pushNamed(
                    RouteNames.commentReply,
                    pathParameters: {'id': targetId},
                    extra: comment,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: NewCommentBox(params: params),
            ),
          ],
        ),
      ),
    );
  }
}
