import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/models/event.dart';

class EventsNotifier extends Notifier<List<Event>> {
  @override
  List<Event> build() {
    return [];
  }

  void addEvent(Event event) {
    state = [event, ...state];
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, List<Event>>(() {
  return EventsNotifier();
});
