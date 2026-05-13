import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class FeedbackItem {
  final String id;
  final String subject;
  final String description;
  final String status; // PENDING, REVIEWED, RESOLVED
  final String? adminNote;
  final DateTime createdAt;
  final FeedbackCategory? category;

  FeedbackItem({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.category,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      id: json['id'],
      subject: json['subject'],
      description: json['description'],
      status: json['status'],
      adminNote: json['adminNote'],
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'] != null ? FeedbackCategory.fromJson(json['category']) : null,
    );
  }
}

class FeedbackCategory {
  final String id;
  final String name;

  FeedbackCategory({required this.id, required this.name});

  factory FeedbackCategory.fromJson(Map<String, dynamic> json) {
    return FeedbackCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class FeedbackRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FeedbackItem>> getFeedbackHistory() async {
    try {
      final response = await _apiClient.dio.get('/api/feedback');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => FeedbackItem.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> submitFeedback({
    required String subject,
    required String description,
    required String categoryId,
  }) async {
    try {
      await _apiClient.dio.post(
        '/api/feedback',
        data: {
          'subject': subject,
          'description': description,
          'categoryId': categoryId,
        },
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<FeedbackCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get(
        '/api/categories',
        queryParameters: {'module': 'FEEDBACK'},
      );
      final List<dynamic> data = response.data['data'];
      return data.map((json) => FeedbackCategory.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

final feedbackRepositoryProvider = Provider((ref) => FeedbackRepository());

final feedbackCategoriesProvider = FutureProvider<List<FeedbackCategory>>((ref) async {
  return ref.watch(feedbackRepositoryProvider).getCategories();
});


