import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:udsm_connect/core/models/post.dart';
import '../../../../core/widgets/avatar_initials.dart';
import '../../../../core/widgets/role_badge.dart';
import '../../../../core/widgets/post_action_button.dart';
import '../../../../core/theme/app_colors.dart';

class PostDetailScreen extends StatelessWidget {
  final Post post;

  const PostDetailScreen({
    Key? key,
    required this.post,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  AvatarInitials(
                    initials: post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                    imageUrl: post.authorProfilePic,
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 8),
                            const RoleBadge(role: UserRole.cr),
                          ],
                        ),
                        Text(
                          '${_formatTimestamp(post.timestamp)} • ${post.category}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Post Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Media
            if (post.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 64, color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Actions Area
            const Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PostActionButton(
                    icon: post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    count: '${post.likes}',
                    onTap: () {},
                    iconColor: post.isLiked ? Theme.of(context).primaryColor : null,
                  ),
                  PostActionButton(icon: Icons.chat_bubble_outline, count: '0', onTap: () {}),
                  PostActionButton(icon: Icons.share_outlined, count: 'Share', onTap: () {}),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 1),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
