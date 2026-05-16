import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:udsm_connect/core/network/api_client.dart';

/// Mirrors `GET /users/{id}` (see openapi / fyp-backend).
class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? registrationNumber;
  final String? collegeId;
  final String? programmeId;
  final String? collegeName;
  final String? programmeName;
  final int? yearOfStudy;
  final String? roleName;
  final int? currentSemester;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.registrationNumber,
    this.collegeId,
    this.programmeId,
    this.collegeName,
    this.programmeName,
    this.yearOfStudy,
    this.roleName,
    this.currentSemester,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final yearRaw = json['yearOfStudy'];
    final college = json['college'] as Map<String, dynamic>?;
    final programme = json['programme'] as Map<String, dynamic>?;
    return UserProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String?,
      collegeId: json['collegeId'] as String?,
      programmeId: json['programmeId'] as String?,
      collegeName: college?['name'] as String?,
      programmeName: programme?['name'] as String?,
      yearOfStudy: yearRaw is int ? yearRaw : int.tryParse('$yearRaw'),
      roleName: json['roleName'] as String?,
      currentSemester: json['currentSemester'] as int?,
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
