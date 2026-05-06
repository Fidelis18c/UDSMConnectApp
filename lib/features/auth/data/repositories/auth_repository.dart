import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response.data);
      await _saveToken(authResponse.token);
      _apiClient.setToken(authResponse.token);
      
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<RegisterResponse> register({
    required String fullName,
    required String registrationNumber,
    required String course,
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
          'course': course,
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

  Future<void> requestPasswordReset(String email) async {
    try {
      await _apiClient.dio.post(
        '/auth/generate-otp',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> verifyOtp(String email, String otpCode) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/verify-otp',
        data: {
          'email': email,
          'otpCode': otpCode,
        },
      );
      return response.data['data']['resetToken'];
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

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
      if (message != null) return message;
      
      // If it's a 401/403/404/500 etc without a message
      return 'Server error: ${e.response?.statusCode}';
    }
    return 'Something went wrong. Please try again.';
  }
}
