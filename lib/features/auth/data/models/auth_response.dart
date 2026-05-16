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
  final String roleId;
  final String? roleName;

  UserData({
    required this.id,
    required this.fullName,
    this.registrationNumber,
    required this.email,
    required this.roleId,
    this.roleName,
  });

  bool get isStudent {
    if (roleName != null) {
      return roleName!.toLowerCase() == 'student';
    }
    // Fallback if roleName is not provided directly, 
    // you might need to adjust this if you know the exact student roleId
    return false;
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    // Login API returns roles: [{ id, name }] — extract first role
    final roles = json['roles'] as List<dynamic>?;
    final firstRole = (roles != null && roles.isNotEmpty)
        ? roles.first as Map<String, dynamic>
        : null;

    final roleId = firstRole?['id'] as String?
        ?? json['roleId'] as String?
        ?? '';

    // Resolve roleName from roles array, direct field, or nested role object
    String? rName = firstRole?['name'] as String?
        ?? json['roleName'] as String?;
    if (rName == null && json['role'] is Map) {
      rName = json['role']['name'] as String?;
    }

    return UserData(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      registrationNumber: json['registrationNumber'] as String?,
      email: json['email'] as String? ?? '',
      roleId: roleId,
      roleName: rName,
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
