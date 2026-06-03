import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/college.dart';

final collegeProvider = FutureProvider<List<College>>((ref) async {
  final apiClient = ApiClient();
  final response = await apiClient.dio.get('/colleges');
  
  final List<dynamic> data = response.data['data'];
  return data.map((json) => College.fromJson(json)).toList();
});
