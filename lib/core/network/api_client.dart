import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  /// Base URL is injected at build/run time via --dart-define=API_BASE_URL=...
  /// Default is always production so testers are never affected.
  ///
  /// For local development run with:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.udsminfo.com/api',
  );

  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        // Snappier failure on bad networks; avoid 30s stalls on every call.
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Verbose body logging is expensive on device — debug only.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: false,
          responseBody: false,
          error: true,
        ),
      );
    }
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}