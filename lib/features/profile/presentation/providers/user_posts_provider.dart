import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/features/announcements/data/posts_repository.dart';

final userPostsProvider = FutureProvider.family<List<Post>, String>((ref, userId) async {
  final repo = ref.read(postsRepositoryProvider);
  return repo.fetchFeed(authorId: userId);
});
