import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:udsm_connect/core/network/api_client.dart';

/// Mirrors `GET /users/{id}` (see openapi / fyp-backend).
class UserProfile {
  final String id;
  final String fullName;
  final String? collegeId;
  final String? programmeId;
  final int? yearOfStudy;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.collegeId,
    this.programmeId,
    this.yearOfStudy,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final yearRaw = json['yearOfStudy'];
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      collegeId: json['collegeId'] as String?,
      programmeId: json['programmeId'] as String?,
      yearOfStudy: yearRaw is int ? yearRaw : int.tryParse('$yearRaw'),
    );
  }
}

class UsersRepository {
  UsersRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<UserProfile> fetchUser(String userId) async {
    final response = await _api.dio.get<Map<String, dynamic>>('/users/$userId');
    final payload = response.data?['data'] as Map<String, dynamic>? ?? {};
    return UserProfile.fromJson(Map<String, dynamic>.from(payload));
  }
}

final usersRepositoryProvider = Provider<UsersRepository>((ref) => UsersRepository());
