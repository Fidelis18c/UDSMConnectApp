import 'package:flutter/material.dart';

enum FeedbackStatus { pending, reviewed, resolved }

class FeedbackModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime timestamp;
  final FeedbackStatus status;

  FeedbackModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.status = FeedbackStatus.pending,
  });

  FeedbackModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? timestamp,
    FeedbackStatus? status,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
