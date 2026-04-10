import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/post.dart';

class AnnouncementsNotifier extends Notifier<List<Post>> {
  @override
  List<Post> build() {
    return [];
  }

  void addPost(Post post) {
    state = [post, ...state];
  }

  void toggleLike(String postId) {
    state = [
      for (final post in state)
        if (post.id == postId)
          post.copyWith(
            isLiked: !post.isLiked,
            likes: post.isLiked ? post.likes - 1 : post.likes + 1,
          )
        else
          post
    ];
  }
}

final announcementsProvider = NotifierProvider<AnnouncementsNotifier, List<Post>>(() {
  return AnnouncementsNotifier();
});
