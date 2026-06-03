import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:udsm_connect/core/models/post.dart';
import 'package:udsm_connect/core/network/api_client.dart';

final postsRepositoryProvider = Provider<PostsRepository>((ref) => PostsRepository());

/// Social feed backed by [`GET /posts`](https://fyp-backend-pi-one.vercel.app/api/posts).
class PostsRepository {
  PostsRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Post>> fetchFeed({int page = 1, int pageSize = 20, String? authorId}) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (authorId != null) queryParameters['authorId'] = authorId;

    final response = await _api.dio.get<Map<String, dynamic>>(
      '/posts',
      queryParameters: queryParameters,
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

  Future<String> createPost({
    required String title,
    required String content,
    String? excerpt,
    required List<Map<String, dynamic>> audiences,
    String type = 'POST',
    String status = 'PUBLISHED',
    String? coverImageId,
    List<String>? mediaIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'type': type,
      'status': status,
      'audiences': audiences,
    };
    if (excerpt != null) body['excerpt'] = excerpt;
    if (coverImageId != null) {
      body['coverImageId'] = coverImageId;
      body['mediaIds'] = [coverImageId];
      body['mediaId'] = coverImageId; // Some backends use singular mediaId
    } else if (mediaIds != null) {
      body['mediaIds'] = mediaIds;
    }

    final response = await _api.dio.post<Map<String, dynamic>>('/posts', data: body);
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw Exception('Failed to create post: No ID returned');
    }
    return id;
  }
}
