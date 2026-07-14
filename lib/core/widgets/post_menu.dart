import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/utils/post_share.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';
import 'package:udsm_connect/features/announcements/presentation/providers/announcements_provider.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';

/// Bottom-sheet menu for a post's three-dots button: share for everyone,
/// delete for the post's author.
void showPostMenu(BuildContext context, WidgetRef ref, Post post) {
  final currentUserId = ref.read(authProvider).user?.id;
  final isOwner = currentUserId != null && currentUserId == post.authorId;

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
            leading:
                const PhosphorIcon(PhosphorIconsRegular.shareNetwork, size: 22),
            title: const Text('Share post'),
            onTap: () {
              Navigator.pop(sheetContext);
              PostShare.sharePost(
                postId: post.id,
                title: post.title,
                text: post.text,
              );
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
                _confirmDeletePost(context, ref, post);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _confirmDeletePost(
    BuildContext context, WidgetRef ref, Post post) async {
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
  if (confirmed != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(postsRepositoryProvider).deletePost(post.id);
    await ref.read(announcementsProvider.notifier).refresh();
    messenger.showSnackBar(const SnackBar(content: Text('Post deleted.')));
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Failed to delete post. Try again.')),
    );
  }
}
