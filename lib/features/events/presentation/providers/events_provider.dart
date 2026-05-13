import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/event.dart';
import '../../data/repositories/event_repository.dart';

final eventRepositoryProvider = Provider((ref) => EventRepository());

final eventCategoriesProvider = FutureProvider<List<EventCategory>>((ref) async {
  return ref.watch(eventRepositoryProvider).getCategories();
});

class EventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  Future<List<Event>> build() async {
    return _fetch();
  }

  Future<List<Event>> _fetch() async {
    try {
      final repo = ref.read(eventRepositoryProvider);
      return await repo.getEvents();
    } catch (e, stack) {
      print('DEBUG: Error fetching events: $e');
      print(stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
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
