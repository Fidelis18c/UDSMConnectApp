import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';

class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;
  EmailNotVerifiedException(this.email, this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  final ApiClient _apiClient = ApiClient();

  /// [identifier] may be email or registration number.
  Future<AuthResponse> login(String identifier, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'identifier': identifier.trim(),
          // legacy field for older backends
          'email': identifier.trim(),
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveSession(authResponse.token, authResponse.user);
      _apiClient.setToken(authResponse.token);

      return authResponse;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 403 &&
          data is Map &&
          data['errors'] is Map &&
          data['errors']['code'] == 'EMAIL_NOT_VERIFIED') {
        final email = data['errors']['email']?.toString() ?? identifier;
        throw EmailNotVerifiedException(
          email,
          data['message']?.toString() ??
              'Verify your UDSM webmail before logging in.',
        );
      }
      throw _handleError(e);
    }
  }

  Future<RegisterResponse> register({
    required String fullName,
    required String registrationNumber,
    required String programmeId,
    required int yearOfStudy,
    required String sex,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'fullName': fullName,
          'registrationNumber': registrationNumber,
          'programmeId': programmeId,
          'yearOfStudy': yearOfStudy,
          'sex': sex,
          'email': email,
          'password': password,
        },
      );

      return RegisterResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> requestOtp(
    String email, {
    String purpose = 'password_reset',
  }) async {
    try {
      await _apiClient.dio.post(
        '/auth/generate-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'purpose': purpose,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Password-reset OTP → returns resetToken.
  Future<String> verifyPasswordResetOtp(String email, String otpCode) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'otpCode': otpCode,
          'purpose': 'password_reset',
        },
      );
      return response.data['data']['resetToken'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Registration email verification (no reset token).
  Future<void> verifyEmailOtp(String email, String otpCode) async {
    try {
      await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'email': email.trim().toLowerCase(),
          'otpCode': otpCode,
          'purpose': 'email_verification',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    try {
      await _apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'resetToken': resetToken,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> _saveSession(String token, UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(_userToJson(user)));
  }

  Map<String, dynamic> _userToJson(UserData user) => {
        'id': user.id,
        'fullName': user.fullName,
        'registrationNumber': user.registrationNumber,
        'email': user.email,
        'roles': user.roleNames.map((name) => {'name': name}).toList(),
      };

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserData?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<UserData?> restoreSession() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      _apiClient.clearToken();
      return null;
    }

    _apiClient.setToken(token);
    final cached = await getCachedUser();

    try {
      final response =
          await _apiClient.dio.get<Map<String, dynamic>>('/users/me');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        if (cached != null) return cached;
        await logout();
        return null;
      }
      final user = UserData.fromJson(Map<String, dynamic>.from(data));
      await _saveSession(token, user);
      return user;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await logout();
        return null;
      }
      if (cached != null) return cached;
      return null;
    } catch (_) {
      if (cached != null) return cached;
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _apiClient.clearToken();
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Connection failed. Please check if the backend is running and reachable.';
    }

    if (e.response != null && e.response?.data != null) {
      final message = e.response?.data['message'];
      if (message != null) return message.toString();
      return 'Server error: ${e.response?.statusCode}';
    }
    return 'Something went wrong. Please try again.';
  }
}
