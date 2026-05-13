import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/lost_found.dart';

class LostFoundRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<LostFoundItem>> getItems({
    int page = 1,
    int pageSize = 20,
    String? type,
    String? categoryId,
    String? status,
    String? search,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/lost-found',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (type != null) 'type': type,
          if (categoryId != null) 'categoryId': categoryId,
          if (status != null) 'status': status,
          if (search != null) 'search': search,
        },
      );

      final List<dynamic> data = response.data['data'];
      return data.map((json) => LostFoundItem.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<LostFoundItem> createItem({
    required String title,
    required String description,
    required String type,
    String? categoryId,
    String? location,
    DateTime? dateLostFound,
    bool isAnonymous = false,
    String? contactInfo,
    List<String>? mediaIds,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'type': type,
        'title': title,
        'description': description,
        'dateLostOrFound': (dateLostFound ?? DateTime.now()).toUtc().toIso8601String(),
        'isAnonymous': isAnonymous,
        'contactInfo': contactInfo,
        'mediaIds': mediaIds ?? [],
      };

      if (categoryId != null) data['categoryId'] = categoryId;
      if (location != null) data['locationSeen'] = location;

      final response = await _apiClient.dio.post(
        '/lost-found',
        data: data,
      );
      return LostFoundItem.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LostFoundCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(
        '/categories',
        queryParameters: {'module': 'LOST_FOUND'},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => LostFoundCategory.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
