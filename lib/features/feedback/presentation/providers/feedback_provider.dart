import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/feedback_repository.dart';

class FeedbackNotifier extends AsyncNotifier<List<FeedbackItem>> {
  FeedbackRepository get _repo => ref.read(feedbackRepositoryProvider);

  @override
  Future<List<FeedbackItem>> build() {
    return _repo.getFeedbackHistory();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.getFeedbackHistory);
  }

  Future<void> submit({
    required String subject,
    required String description,
    required String categoryId,
  }) async {
    await _repo.submitFeedback(
      subject: subject,
      description: description,
      categoryId: categoryId,
    );
    await refresh();
  }
}

final feedbackProvider =
    AsyncNotifierProvider<FeedbackNotifier, List<FeedbackItem>>(FeedbackNotifier.new);
