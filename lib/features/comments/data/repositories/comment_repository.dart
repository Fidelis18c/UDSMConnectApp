import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:udsm_connect/core/network/api_client.dart';
import '../models/comment.dart';

class CommentRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Comment>> getComments({
    required String targetId,
    required String targetType,
  }) async {
    final response = await _apiClient.dio.get(
      '/comments',
      queryParameters: {
        'targetId': targetId,
        'targetType': targetType,
      },
    );
    final List<dynamic> data = response.data['data'];
    return data.map((c) => Comment.fromJson(Map<String, dynamic>.from(c))).toList();
  }

  /// Uploads a file to /api/media/upload and returns the media record id.
  Future<String> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final response = await _apiClient.dio.post('/media/upload', data: formData);
    return response.data['data']['id'] as String;
  }

  Future<Comment> postComment({
    required String targetId,
    required String targetType,
    required String content,
    String? parentId,
    String? mediaId,
  }) async {
    final response = await _apiClient.dio.post('/comments', data: {
      'targetId': targetId,
      'targetType': targetType,
      'content': content,
      if (parentId != null) 'parentId': parentId,
      if (mediaId != null) 'mediaId': mediaId,
    });
    return Comment.fromJson(Map<String, dynamic>.from(response.data['data']));
  }

  Future<void> deleteComment(String id) async {
    await _apiClient.dio.delete('/comments/$id');
  }

  Future<void> editComment(String id, String content) async {
    await _apiClient.dio.patch('/comments/$id', data: {'content': content});
  }

  Future<void> toggleLike(String id) async {
    await _apiClient.dio.post('/comments/$id/reactions');
  }
}

