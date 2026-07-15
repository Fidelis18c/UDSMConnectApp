import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/programme.dart';

/// Filter key for programmes list (college and/or department).
class ProgrammeQuery {
  final String? collegeId;
  final String? departmentId;

  const ProgrammeQuery({this.collegeId, this.departmentId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgrammeQuery &&
          collegeId == other.collegeId &&
          departmentId == other.departmentId;

  @override
  int get hashCode => Object.hash(collegeId, departmentId);
}

final programmeProvider =
    FutureProvider.family<List<Programme>, ProgrammeQuery>((ref, query) async {
  final apiClient = ApiClient();
  final params = <String, dynamic>{
    'pageSize': 100,
  };
  if (query.collegeId != null && query.collegeId!.isNotEmpty) {
    params['collegeId'] = query.collegeId;
  }
  if (query.departmentId != null && query.departmentId!.isNotEmpty) {
    params['departmentId'] = query.departmentId;
  }

  final response = await apiClient.dio.get(
    '/programmes',
    queryParameters: params,
  );

  final List<dynamic> data = response.data['data'] as List<dynamic>? ?? [];
  return data
      .map((json) => Programme.fromJson(Map<String, dynamic>.from(json as Map)))
      .toList();
});

/// Back-compat: college-only filter used by older call sites.
final programmeByCollegeProvider =
    FutureProvider.family<List<Programme>, String?>((ref, collegeId) {
  return ref.watch(
    programmeProvider(ProgrammeQuery(collegeId: collegeId)).future,
  );
});
