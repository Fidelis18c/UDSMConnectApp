import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/avatar_initials.dart';
import 'package:udsm_connect/features/auth/presentation/providers/auth_provider.dart';
import '../../data/models/comment.dart';
import '../providers/comments_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

class CommentSection extends ConsumerWidget {
  final String targetId;
  final String targetType;

  const CommentSection({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = CommentsParams(targetId: targetId, targetType: targetType);
    final commentsAsync = ref.watch(commentsQueryProvider(params));
    final currentUserId = ref.watch(authProvider).user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
          child: Row(
            children: [
              const Icon(Icons.comment_outlined, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                'Comments',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              commentsAsync.whenOrNull(
                    data: (list) => Text(
                      '  (${_totalCount(list)})',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textHint,
                      ),
                    ),
                  ) ??
                  const SizedBox.shrink(),
            ],
          ),
        ),

        // New top-level comment box
        _NewCommentBox(params: params),
        const SizedBox(height: 20),

        // Thread
        commentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text('Failed to load comments',
              style: GoogleFonts.inter(color: Colors.red, fontSize: 13)),
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No comments yet. Be the first!',
                    style: GoogleFonts.inter(
                        color: AppColors.textHint, fontSize: 13),
                  ),
                ),
              );
            }
            return Column(
              children: comments
                  .map((c) => _CommentItem(
                        comment: c,
                        depth: 0,
                        params: params,
                        currentUserId: currentUserId,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  int _totalCount(List<Comment> list) =>
      list.fold(0, (sum, c) => sum + 1 + c.replyCount);
}

// ─────────────────────────────────────────────────────────────────────────────
// New comment / reply input box
// ─────────────────────────────────────────────────────────────────────────────

class _NewCommentBox extends ConsumerStatefulWidget {
  final CommentsParams params;
  final String? parentId;
  final String? hintOverride;
  final VoidCallback? onSuccess;

  const _NewCommentBox({
    required this.params,
    this.parentId,
    this.hintOverride,
    this.onSuccess,
  });

  @override
  ConsumerState<_NewCommentBox> createState() => _NewCommentBoxState();
}

class _NewCommentBoxState extends ConsumerState<_NewCommentBox> {
  final TextEditingController _controller = TextEditingController();
  bool _posting = false;
  XFile? _pickedImage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pickedImage == null) return;
    setState(() => _posting = true);
    final ok = await ref.read(commentsMutationsProvider).post(
          params: widget.params,
          content: text.isEmpty ? '📷' : text,
          parentId: widget.parentId,
          imageFile: _pickedImage,
        );
    if (!mounted) return;
    setState(() {
      _posting = false;
      if (ok) _pickedImage = null;
    });
    if (ok) {
      _controller.clear();
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview strip
        if (_pickedImage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _pickedImage!.path,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_pickedImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() => _pickedImage = null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: widget.hintOverride ?? 'Write a comment…',
                    hintStyle: GoogleFonts.inter(
                        color: AppColors.textHint, fontSize: 13),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Image picker button
            GestureDetector(
              onTap: _posting ? null : _pickImage,
              child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 10),
                child: Icon(
                  Icons.image_outlined,
                  color: _pickedImage != null ? AppColors.primary : AppColors.textHint,
                  size: 26,
                ),
              ),
            ),
            GestureDetector(
              onTap: _posting ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _posting ? AppColors.textHint : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: _posting
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recursive comment node
// ─────────────────────────────────────────────────────────────────────────────

class _CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final int depth;
  final CommentsParams params;
  final String? currentUserId;
  final String? parentAuthorName;

  const _CommentItem({
    required this.comment,
    required this.depth,
    required this.params,
    this.currentUserId,
    this.parentAuthorName,
  });

  @override
  ConsumerState<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<_CommentItem> {
  bool _showReply = false;
  bool _collapsed = false;
  bool _editing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.currentUserId == widget.comment.authorId;
    final hasChildren = widget.comment.children.isNotEmpty;
    final cleanAuthorName = widget.comment.authorName.split('@')[0].trim();
    final cleanParentAuthorName = widget.parentAuthorName?.split('@')[0].trim();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              AvatarInitials(
                initials: cleanAuthorName.isNotEmpty ? cleanAuthorName[0].toUpperCase() : '?',
                imageUrl: widget.comment.authorProfilePic,
                radius: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: cleanAuthorName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: ' · ${_timeAgo(widget.comment.createdAt)}',
                                  style: GoogleFonts.inter(
                                      fontSize: 13, color: AppColors.textHint),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Replying to logic...
                    if (widget.depth > 0 && cleanParentAuthorName != null) ...[
                      const SizedBox(height: 2),
                      Row(
                         children: [
                            Text(
                              'Replying to ',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHint),
                            ),
                            Text(
                              cleanParentAuthorName!,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
                            ),
                         ],
                      ),
                    ],

                    const SizedBox(height: 4),

                    // Content or edit box
                    if (_editing)
                      Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _editController,
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                              maxLines: null,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _ActionChip(
                                label: 'Save',
                                color: AppColors.primary,
                                onTap: () async {
                                  final ok = await ref.read(commentsMutationsProvider).edit(
                                        params: widget.params,
                                        id: widget.comment.id,
                                        content: _editController.text.trim(),
                                      );
                                  if (ok) setState(() => _editing = false);
                                },
                              ),
                              const SizedBox(width: 8),
                              _ActionChip(
                                label: 'Cancel',
                                onTap: () {
                                  setState(() {
                                    _editing = false;
                                    _editController.text = widget.comment.content;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Text(
                        widget.comment.content,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFEFEFEF),
                          height: 1.4,
                        ),
                      ),

                    // Attached image (if any)
                    if (!_editing && widget.comment.imageUrl != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          widget.comment.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 160,
                              color: const Color(0xFF1E1E1E),
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(
                                  color: AppColors.primary, strokeWidth: 2),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Twitter Action bar for Comments
                    Row(
                      children: [
                        _ActionIcon(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: widget.comment.replyCount > 0 ? '${widget.comment.replyCount}' : null,
                          onTap: () => setState(() => _showReply = !_showReply),
                        ),
                        const SizedBox(width: 24),
                        _ActionIcon(
                          icon: widget.comment.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: widget.comment.isLiked
                              ? AppColors.primary
                              : AppColors.textHint,
                          label: widget.comment.likeCount > 0
                              ? '${widget.comment.likeCount}'
                              : null,
                          onTap: () => ref
                              .read(commentsMutationsProvider)
                              .toggleLike(params: widget.params, id: widget.comment.id),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 24),
                          _ActionIcon(
                            icon: Icons.edit_outlined,
                            onTap: () => setState(() => _editing = true),
                          ),
                          const SizedBox(width: 24),
                          _ActionIcon(
                            icon: Icons.delete_outline_rounded,
                            color: Colors.red.shade400,
                            onTap: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: const Text('Delete comment?',
                                      style: TextStyle(color: Colors.white)),
                                  content: const Text(
                                      'This will also delete all replies.',
                                      style: TextStyle(color: Colors.white70)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('CANCEL',
                                          style: TextStyle(color: AppColors.textHint)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('DELETE',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref.read(commentsMutationsProvider).delete(
                                      params: widget.params,
                                      id: widget.comment.id,
                                    );
                              }
                            },
                          ),
                        ],
                        if (hasChildren) ...[
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() => _collapsed = !_collapsed),
                            child: Row(
                              children: [
                                Text(
                                  _collapsed ? 'Show replies' : 'Hide',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  _collapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Inline reply box
          if (_showReply)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 40),
              child: _NewCommentBox(
                params: widget.params,
                parentId: widget.comment.id,
                hintOverride: 'Post your reply',
                onSuccess: () => setState(() => _showReply = false),
              ),
            ),

          // ── Recursively render children with continuous left border ────
          if (!_collapsed && hasChildren)
            Container(
              margin: const EdgeInsets.only(left: 13, top: 4),
              padding: const EdgeInsets.only(left: 25),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFF333333),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: widget.comment.children.map(
                  (child) => _CommentItem(
                    comment: child,
                    depth: widget.depth + 1,
                    params: widget.params,
                    currentUserId: widget.currentUserId,
                    parentAuthorName: widget.comment.authorName, // Pass down parent author
                  ),
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label!,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  color: c,
                  fontWeight: FontWeight.w400),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textHint;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: c,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
