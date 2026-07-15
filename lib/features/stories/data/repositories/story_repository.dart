import 'package:dio/dio.dart';
import 'package:udsm_connect/core/models/story.dart';
import 'package:udsm_connect/core/network/api_client.dart';

class StoryRepository {
  final Dio _dio;

  StoryRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  Future<List<Story>> fetchStories() async {
    try {
      final response = await _dio.get('/stories');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((e) => Story.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch stories: $e');
    }
  }

  Future<void> createStory(String mediaId, {String? caption}) async {
    await _dio.post('/stories', data: {
      'mediaId': mediaId,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
    });
  }

  Future<void> markViewed(String storyId) async {
    try {
      await _dio.post('/stories/$storyId/view');
    } catch (_) {
      // Fire-and-forget view tracking
    }
  }

  /// Toggle like on a story. Returns true if now liked, false if unliked.
  Future<bool> toggleLike(String storyId) async {
    final response = await _dio.post('/stories/$storyId/reactions');
    final action = response.data['data']?['action'] as String?;
    if (action == 'liked') return true;
    if (action == 'unliked') return false;
    final isLiked = response.data['data']?['isLiked'];
    return isLiked == true;
  }
}
