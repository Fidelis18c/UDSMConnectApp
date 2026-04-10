import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/story.dart';

class StoriesNotifier extends Notifier<List<Story>> {
  @override
  List<Story> build() {
    return [];
  }

  void addStory(Story story) {
    state = [story, ...state];
  }
}

final storiesProvider = NotifierProvider<StoriesNotifier, List<Story>>(() {
  return StoriesNotifier();
});
