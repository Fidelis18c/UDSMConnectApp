import 'package:dio/dio.dart';

import 'package:udsm_connect/core/network/api_client.dart';
import 'package:udsm_connect/features/auth/data/users_repository.dart';

class AnnouncementsRepository {
  AnnouncementsRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// Default audiences for `POST /announcements`: class cohort when programme + year exist, otherwise ALL.
  static List<Map<String, dynamic>> audiencesFor(UserProfile? profile) {
    final programmeId = profile?.programmeId;
    final year = profile?.yearOfStudy;
    if (programmeId != null &&
        programmeId.isNotEmpty &&
        year != null &&
        year >= 1 &&
        year <= 7) {
      return [
        {'targetType': 'PROGRAMME_YEAR', 'programmeId': programmeId, 'yearOfStudy': year},
      ];
    }
    return [
      {'targetType': 'ALL'},
    ];
  }

  /// `POST /media/upload` (multipart `file`).
  Future<String> uploadMediaBytes(List<int> bytes, {required String filename}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
    );
    final data = response.data?['data'] as Map<String, dynamic>? ?? {};
    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }
    return id;
  }

  /// `POST /announcements` — see openapi `Create an announcement`.
  Future<String> createAnnouncement({
    required String title,
    required String content,
    String? excerpt,
    required List<Map<String, dynamic>> audiences,
    String type = 'ANNOUNCEMENT',
    String status = 'PUBLISHED',
    String? coverImageId,
    List<String>? mediaIds,
    String? categoryId,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'content': content,
      'type': type,
      'status': status,
      'audiences': audiences,
    };
    final ex = excerpt;
    if (ex != null && ex.isNotEmpty) body['excerpt'] = ex;
    if (coverImageId != null && coverImageId.isNotEmpty) body['coverImageId'] = coverImageId;
    if (categoryId != null && categoryId.isNotEmpty) body['categoryId'] = categoryId;
    if (academicYearId != null && academicYearId.isNotEmpty) body['academicYearId'] = academicYearId;
    if (mediaIds != null && mediaIds.isNotEmpty) body['mediaIds'] = mediaIds;

    final response = await _api.dio.post<Map<String, dynamic>>('/announcements', data: body);
    final payload = response.data?['data'];
    final mid =
        payload is Map<String, dynamic>
            ? payload['id'] as String?
            : null;
    if (mid != null && mid.isNotEmpty) return mid;

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }
}
