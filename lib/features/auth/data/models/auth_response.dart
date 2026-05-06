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

  UserData({
    required this.id,
    required this.fullName,
    this.registrationNumber,
    required this.email,
    required this.roleId,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      fullName: json['fullName'],
      registrationNumber: json['registrationNumber'], // This can be null
      email: json['email'],
      roleId: json['roleId'],
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
