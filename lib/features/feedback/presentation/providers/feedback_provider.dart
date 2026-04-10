import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/feedback_model.dart';

class FeedbackNotifier extends Notifier<List<FeedbackModel>> {
  @override
  List<FeedbackModel> build() {
    return [];
  }

  void addFeedback(FeedbackModel feedback) {
    state = [feedback, ...state];
  }
}

final feedbackProvider = NotifierProvider<FeedbackNotifier, List<FeedbackModel>>(() {
  return FeedbackNotifier();
});
