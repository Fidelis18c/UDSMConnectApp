import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Announcement>> getAnnouncements({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? categoryId,
    String? search,
    bool? isForYou,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/api/announcements',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (type != null) 'type': type,
          if (categoryId != null) 'categoryId': categoryId,
          if (search != null) 'search': search,
          if (isForYou != null) 'isForYou': isForYou,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => Announcement.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Announcement> getAnnouncementDetails(String id) async {
    try {
      final response = await _apiClient.dio.get('/api/announcements/$id');
      return Announcement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    String? excerpt,
    required String type,
    String status = 'PUBLISHED',
    String? categoryId,
    String? coverImageId,
    List<Map<String, dynamic>>? audiences,
    List<String>? mediaIds,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'excerpt': excerpt ?? "",
        'type': type,
        'status': status,
        'audiences': audiences ?? [{'targetType': 'ALL'}],
        'mediaIds': mediaIds ?? [],
      };

      if (categoryId != null) data['categoryId'] = categoryId;
      if (coverImageId != null) data['coverImageId'] = coverImageId;

      final response = await _apiClient.dio.post(
        '/api/announcements',
        data: data,
      );
      return Announcement.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AnnouncementCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/categories',
        queryParameters: {'module': 'ANNOUNCEMENT'},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => AnnouncementCategory.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
