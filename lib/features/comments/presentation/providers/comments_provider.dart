import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/comment.dart';
import '../../data/repositories/comment_repository.dart';

// ── Repository ─────────────────────────────────────────────────────────────────
final commentRepositoryProvider = Provider((_) => CommentRepository());

// ── Input params ───────────────────────────────────────────────────────────────
class CommentsParams {
  final String targetId;
  final String targetType;
  const CommentsParams({required this.targetId, required this.targetType});

  @override
  bool operator ==(Object other) =>
      other is CommentsParams &&
      other.targetId == targetId &&
      other.targetType == targetType;

  @override
  int get hashCode => Object.hash(targetId, targetType);
}

// ── Query Provider ─────────────────────────────────────────────────────────────
final commentsQueryProvider = FutureProvider.family<List<Comment>, CommentsParams>((ref, arg) async {
  return ref.read(commentRepositoryProvider).getComments(
        targetId: arg.targetId,
        targetType: arg.targetType,
      );
});

// ── Mutations Service ────────────────────────────────────────────────────────
class CommentsMutations {
  final Ref ref;
  CommentsMutations(this.ref);

  Future<bool> post({
    required CommentsParams params,
    required String content,
    String? parentId,
    XFile? imageFile,
  }) async {
    try {
      String? mediaId;
      if (imageFile != null) {
        mediaId = await ref.read(commentRepositoryProvider).uploadImage(imageFile);
      }
      await ref.read(commentRepositoryProvider).postComment(
            targetId: params.targetId,
            targetType: params.targetType,
            content: content,
            parentId: parentId,
            mediaId: mediaId,
          );
      ref.invalidate(commentsQueryProvider(params));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete({
    required CommentsParams params,
    required String id,
  }) async {
    try {
      await ref.read(commentRepositoryProvider).deleteComment(id);
      ref.invalidate(commentsQueryProvider(params));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> edit({
    required CommentsParams params,
    required String id,
    required String content,
  }) async {
    try {
      await ref.read(commentRepositoryProvider).editComment(id, content);
      ref.invalidate(commentsQueryProvider(params));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleLike({
    required CommentsParams params,
    required String id,
  }) async {
    try {
      await ref.read(commentRepositoryProvider).toggleLike(id);
      ref.invalidate(commentsQueryProvider(params));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final commentsMutationsProvider = Provider((ref) => CommentsMutations(ref));
