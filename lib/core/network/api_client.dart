import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    // If you are hotspotting from your phone:
    // 1. Run 'ipconfig' on your PC.
    // 2. Look for "IPv4 Address" under your Wireless LAN adapter (usually 192.168.43.x).
    // 3. Replace the IP below with that address.
    String baseUrl = 'http://localhost:3000/api';
    
    if (!kIsWeb && Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android Emulators to reach the host PC
      // For physical devices, use your PC's IP (e.g., 'http://192.168.43.100:3000/api')
      baseUrl = 'http://192.168.1.109:3000/api'; 
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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