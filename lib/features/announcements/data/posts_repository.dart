import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/network/api_client.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) => PostsRepository());

/// Social feed backed by [`GET /posts`](https://fyp-backend-pi-one.vercel.app/api/posts).
class PostsRepository {
  PostsRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Post>> fetchFeed({int page = 1, int pageSize = 20}) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/posts',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );

    final rawList = response.data?['data'] as List<dynamic>? ?? [];
    return rawList
        .map((e) => Post.fromPostsListJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Post> fetchDetail(String id) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/posts/$id');
    final payload = response.data?['data'] as Map<String, dynamic>? ?? {};
    return Post.fromPostsDetailJson(Map<String, dynamic>.from(payload));
  }

  Future<void> toggleLike(String postId) async {
    await _api.dio.post<void>('/posts/$postId/reactions');
  }
}
