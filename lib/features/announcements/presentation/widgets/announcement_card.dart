import 'package:flutter/material.dart';
import '../../../../core/widgets/avatar_initials.dart';
import '../../../../core/widgets/role_badge.dart';
import '../../../../core/widgets/post_action_button.dart';
import '../../../../core/models/post.dart';

class AnnouncementCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const AnnouncementCard({
    Key? key,
    required this.post,
    required this.onTap,
    required this.onLike,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AvatarInitials(
                    initials: post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                    imageUrl: post.authorProfilePic,
                    radius: 20,
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            const RoleBadge(role: UserRole.cr), // Hardcoded for now, model can be extended
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTimestamp(post.timestamp)} • ${post.category}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Body Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                post.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 12),

            // Image attachment
            if (post.imageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
                  child: Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                    ),
                  ),
                ),
              ),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  PostActionButton(
                    icon: post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                    count: '${post.likes}',
                    onTap: onLike,
                    iconColor: post.isLiked ? Theme.of(context).primaryColor : null,
                  ),
                  PostActionButton(
                    icon: Icons.chat_bubble_outline,
                    count: '0',
                    onTap: () {},
                  ),
                  const Spacer(),
                  PostActionButton(
                    icon: Icons.share_outlined,
                    count: '',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    // Simple helper for now
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
