import '../../../../core/models/user_model.dart';

class AuthResponse {
  final String token;
  final UserData user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['data']['token'],
      user: UserData.fromJson(json['data']['user']),
    );
  }
}

class UserData {
  final String id;
  final String fullName;
  final String? registrationNumber;
  final String email;

  /// All role names assigned to this user (e.g. ["Student", "Admin", "Daruso leader"])
  final List<String> roleNames;

  UserData({
    required this.id,
    required this.fullName,
    this.registrationNumber,
    required this.email,
    required this.roleNames,
  });

  // ---------- Convenience role getters ----------

  /// The set of privileged roles that can perform admin-like actions
  static const _privilegedRoles = {
    'admin',
    'daruso leader',
    'staff',
    'lecturer',
    'super admin',
    'class representative',
  };

  /// True only if the user has NO privileged roles (i.e., a plain student)
  bool get isStudent {
    final lower = roleNames.map((r) => r.toLowerCase().replaceAll('_', ' ')).toSet();
    return lower.intersection(_privilegedRoles).isEmpty;
  }

  bool get isAdmin =>
      roleNames.any((r) => r.toLowerCase().replaceAll('_', ' ') == 'admin' || r.toLowerCase().replaceAll('_', ' ') == 'super admin');

  bool get isDarusoLeader =>
      roleNames.any((r) => r.toLowerCase().replaceAll('_', ' ') == 'daruso leader');

  bool get isStaff =>
      roleNames.any((r) => r.toLowerCase().replaceAll('_', ' ') == 'staff');

  bool get isLecturer =>
      roleNames.any((r) => r.toLowerCase().replaceAll('_', ' ').contains('lecturer'));

  /// Lecturer or general staff (not admin) — department-scoped in compose.
  bool get isDepartmentStaff => isLecturer || isStaff;

  bool get isClassRepresentative =>
      roleNames.any((r) => r.toLowerCase().replaceAll('_', ' ') == 'class representative');

  bool get hasPrivilegedRole => !isStudent;

  bool get canPostNews {
    final allowedRoles = {
      'admin',
      'super admin',
      'daruso leader',
      'staff',
      'lecturer',
      'college rep',
      'college representative',
      'class representative',
    };
    final lower = roleNames.map((r) => r.toLowerCase().replaceAll('_', ' ')).toSet();
    return lower.intersection(allowedRoles).isNotEmpty ||
        lower.any((r) => r.contains('lecturer') || r.contains('class rep'));
  }

  /// Only admins, staff/lecturers, and DARUSO/college leaders can add Stories.
  /// Class Representatives are explicitly excluded.
  bool get canAddStories {
    final allowedRoles = {
      'admin',
      'super admin',
      'daruso leader',
      'staff',
      'lecturer',
      'college rep',
      'college representative',
    };
    final lower = roleNames.map((r) => r.toLowerCase().replaceAll('_', ' ')).toSet();
    return lower.intersection(allowedRoles).isNotEmpty ||
        lower.any((r) => r.contains('lecturer'));
  }

  // -----------------------------------------------

  factory UserData.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'] as List<dynamic>?;

    List<String> names = [];
    if (roles != null && roles.isNotEmpty) {
      names = roles
          .map((r) => (r as Map<String, dynamic>)['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } else {
      // Single-role fallback (legacy)
      final singleName = json['roleName'] as String?
          ?? (json['role'] is Map ? json['role']['name'] as String? : null);
      if (singleName != null && singleName.isNotEmpty) names = [singleName];
    }

    return UserData(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String?,
      email: json['email'] as String? ?? '',
      roleNames: names,
    );
  }

  UserModel toUserModel() {
    return UserModel(
      id: id,
      name: fullName,
      registrationNumber: registrationNumber ?? 'N/A',
      email: email,
      college: 'Unknown',
      programme: 'Unknown',
      year: 'Unknown',
      phone: '',
    );
  }
}

class RegisterResponse {
  final bool success;
  final String message;

  RegisterResponse({
    required this.success,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? 'Registration successful',
    );
  }
}
