import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/programme.dart';

final programmeProvider = FutureProvider<List<Programme>>((ref) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/programmes');
  
  // The API returns paginated response: { success: true, data: [...], meta: {...} }
  // or sometimes just the list depending on how api-response is structured.
  // Based on app/api/programmes/route.ts, it returns paginatedResponse(list, total, page, pageSize)
  
  final List<dynamic> data = response.data['data'];
  return data.map((json) => Programme.fromJson(json)).toList();
});
