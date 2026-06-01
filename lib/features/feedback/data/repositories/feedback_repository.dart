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
    FeedbackCategory? category;
    if (json['category'] != null) {
      category = FeedbackCategory.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categoryId'] != null && json['categoryName'] != null) {
      category = FeedbackCategory(
        id: json['categoryId'] as String,
        name: json['categoryName'] as String,
      );
    }

    return FeedbackItem(
      id: json['id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      adminNote: json['adminNotes'] as String? ?? json['adminNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: category,
    );
  }
}

class FeedbackCategory {
  final String id;
  final String name;

  FeedbackCategory({required this.id, required this.name});

  factory FeedbackCategory.fromJson(Map<String, dynamic> json) {
    return FeedbackCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class FeedbackRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<FeedbackItem>> getFeedbackHistory() async {
    final response = await _apiClient.dio.get('/feedback');
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => FeedbackItem.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<void> submitFeedback({
    required String subject,
    required String description,
    required String categoryId,
  }) async {
    await _apiClient.dio.post(
      '/feedback',
      data: {
        'subject': subject,
        'description': description,
        'categoryId': categoryId,
      },
    );
  }

  Future<List<FeedbackCategory>> getCategories() async {
    final response = await _apiClient.dio.get(
      '/categories',
      queryParameters: {'module': 'FEEDBACK'},
    );
    final List<dynamic> data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => FeedbackCategory.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}

final feedbackRepositoryProvider = Provider((ref) => FeedbackRepository());

final feedbackCategoriesProvider = FutureProvider<List<FeedbackCategory>>((ref) async {
  return ref.watch(feedbackRepositoryProvider).getCategories();
});
