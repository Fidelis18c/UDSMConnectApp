import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/network/api_client.dart';

class Media {
  final String id;
  final String url;
  final String type;

  Media({required this.id, required this.url, required this.type});

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      url: json['url'],
      type: json['type'],
    );
  }
}

class MediaRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Media> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          // You might need to set contentType based on extension if backend is strict
          contentType: MediaType('image', fileName.split('.').last),
        ),
      });

      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
      );

      return Media.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Media> uploadBytes(List<int> bytes, String fileName, {String mimeType = 'image'}) async {
    try {
      String ext = fileName.split('.').last.toLowerCase();
      if (ext == 'jpg') ext = 'jpeg';
      if (!['jpeg', 'png', 'webp', 'gif'].contains(ext) && mimeType == 'image') {
        ext = 'jpeg'; // Default to jpeg if unknown or missing from picker
      }
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName.contains('.') ? fileName : '$fileName.jpg',
          contentType: MediaType(mimeType, ext),
        ),
      });

      final response = await _apiClient.dio.post(
        '/media/upload',
        data: formData,
      );

      return Media.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
