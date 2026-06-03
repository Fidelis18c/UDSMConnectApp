import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/department.dart';

final departmentProvider = FutureProvider.family<List<Department>, String?>((ref, collegeId) async {
  final apiClient = ApiClient();
  final url = collegeId != null ? '/departments?collegeId=$collegeId' : '/departments';
  final response = await apiClient.dio.get(url);
  
  final List<dynamic> data = response.data['data'];
  return data.map((json) => Department.fromJson(json)).toList();
});
