import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScrollVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool isVisible) {
    state = isVisible;
  }
}

final scrollVisibilityProvider = NotifierProvider<ScrollVisibilityNotifier, bool>(ScrollVisibilityNotifier.new);
