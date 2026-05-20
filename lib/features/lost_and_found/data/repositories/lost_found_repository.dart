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
  }) async {
    final response = await _apiClient.dio.get(
      '/lost-found',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
      },
    );
    final List<dynamic> data = response.data['data'];
    return data.map((json) => LostFoundItem.fromJson(json)).toList();
  }

  Future<LostFoundItem> getItemDetail(String id) async {
    final response = await _apiClient.dio.get('/lost-found/$id');
    return LostFoundItem.fromJson(response.data['data']);
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
    final Map<String, dynamic> data = {
      'type': type,
      'title': title,
      'description': description,
      'dateLostOrFound':
          (dateLostFound ?? DateTime.now()).toUtc().toIso8601String().split('T')[0],
      'isAnonymous': isAnonymous,
      if (contactInfo != null && contactInfo.isNotEmpty) 'contactInfo': contactInfo,
      if (categoryId != null) 'categoryId': categoryId,
      if (location != null && location.isNotEmpty) 'locationSeen': location,
      'mediaIds': mediaIds ?? [],
    };

    final response = await _apiClient.dio.post('/lost-found', data: data);
    return LostFoundItem.fromJson(response.data['data']);
  }

  Future<LostFoundItem> updateItem(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.dio.put('/lost-found/$id', data: data);
    return LostFoundItem.fromJson(response.data['data']);
  }

  Future<void> resolveItem(String id) async {
    await _apiClient.dio.post('/lost-found/$id/resolve');
  }

  Future<void> deleteItem(String id) async {
    await _apiClient.dio.delete('/lost-found/$id');
  }

  Future<List<LostFoundCategory>> getCategories() async {
    final response = await _apiClient.dio.get(
      '/categories',
      queryParameters: {'module': 'LOST_FOUND'},
    );
    final List<dynamic> data = response.data['data'];
    return data.map((json) => LostFoundCategory.fromJson(json)).toList();
  }
}
