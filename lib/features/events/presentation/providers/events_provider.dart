import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/event.dart';
import '../../../../core/models/attendee.dart';
import '../../data/repositories/event_repository.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

final eventCategoriesProvider = FutureProvider<List<EventCategory>>((ref) async {
  return ref.watch(eventRepositoryProvider).getCategories();
});

class SelectedEventCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? val) => state = val;
}

final selectedEventCategoryIdProvider = NotifierProvider<SelectedEventCategoryNotifier, String?>(() {
  return SelectedEventCategoryNotifier();
});

// Search query for client-side filtering
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String val) => state = val;
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    final categoryId = ref.watch(selectedEventCategoryIdProvider);
    return _fetch(categoryId: categoryId);
  }

  Future<List<Event>> _fetch({String? categoryId}) async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      return await repo.getEvents(categoryId: categoryId);
    } catch (e, stack) {
      print('DEBUG: Error fetching events: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    final categoryId = ref.read(selectedEventCategoryIdProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch(categoryId: categoryId));
  }

  Future<bool> createEvent(Map<String, dynamic> data) async {
    try {
      print('DEBUG: Creating event with data: $data');
      final repo = ref.read(eventRepositoryProvider);
      await repo.createEvent(data);
      print('DEBUG: Event created successfully in repo');
      refresh();
      return true;
    } catch (e, stack) {
      print('DEBUG: Failed to create event: $e');
      print(stack);
      return false;
    }
  }
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, List<Event>>(() {
  return EventsNotifier();
});

// Upcoming events filtered by search query (client-side)
final filteredUpcomingEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(eventsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final now = DateTime.now();

  return eventsAsync.whenData((events) {
    final upcoming = events.where((e) => e.endDateTime.isAfter(now)).toList();
    if (query.isEmpty) return upcoming;
    return upcoming
        .where((e) =>
            e.title.toLowerCase().contains(query) ||
            e.location.toLowerCase().contains(query))
        .toList();
  });
});

// Past events: events where endDateTime is before now
final pastEventsProvider = FutureProvider<List<Event>>((ref) async {
  final categoryId = ref.watch(selectedEventCategoryIdProvider);
  try {
    final repo = ref.read(eventRepositoryProvider);
    final all = await repo.getEvents(
      upcoming: false,
      categoryId: categoryId,
      pageSize: 20,
    );
    final now = DateTime.now();
    return all.where((e) => e.endDateTime.isBefore(now)).toList();
  } catch (e) {
    return [];
  }
});
// ─────────────────────────────────────────────────────────────────────────────
// RSVP State — tracks which events this session the user is attending
// Key: eventId, Value: true = GOING, false = not attending
// ─────────────────────────────────────────────────────────────────────────────

class RsvpStateNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => {};

  bool isAttending(String eventId) => state[eventId] ?? false;

  void setAttending(String eventId, {required bool attending}) {
    state = {...state, eventId: attending};
  }
}

final rsvpStateProvider =
    NotifierProvider<RsvpStateNotifier, Map<String, bool>>(RsvpStateNotifier.new);

// ─────────────────────────────────────────────────────────────────────────────
// Attendees — fetched on demand by organizer
// ─────────────────────────────────────────────────────────────────────────────

final attendeesProvider =
    FutureProvider.family<List<Attendee>, String>((ref, eventId) async {
  return ref.read(eventRepositoryProvider).getAttendees(eventId);
});
