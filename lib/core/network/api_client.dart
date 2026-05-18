import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  /// Local backend for debug/web testing.
  /// Change this to your machine's LAN IP (e.g. http://192.168.x.x:3000/api)
  /// when testing on a physical Android/iOS device.
  static const String _localUrl = 'http://localhost:3000/api';
  static const String _productionUrl = 'https://fyp-backend-pi-one.vercel.app/api';

  static String get _baseUrl => kDebugMode ? _localUrl : _productionUrl;

  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and token handling
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  void setToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    dio.options.headers.remove('Authorization');
  }
}