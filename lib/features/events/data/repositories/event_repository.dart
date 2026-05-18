import '../../../../core/network/api_client.dart';
import '../../../../core/models/event.dart';
import '../../../../core/models/attendee.dart';

class EventRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Event>> getEvents({
    int page = 1,
    int pageSize = 20,
    String? categoryId,
    String? status = 'PUBLISHED',
    bool? upcoming,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/events',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (categoryId != null) 'categoryId': categoryId,
          if (status != null) 'status': status,
          if (upcoming != null) 'upcoming': upcoming,
        },
      );
      final List<dynamic> data = response.data['data'];
      return data.map<Event>((json) => Event.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Event> getEventDetails(String id) async {
    try {
      final response = await _apiClient.dio.get('/events/$id');
      return Event.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// RSVP as GOING (upserted on backend — safe to call multiple times)
  Future<void> rsvpEvent(String eventId) async {
    try {
      await _apiClient.dio.post(
        '/events/$eventId/rsvp',
        data: {'status': 'GOING'},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Remove the current user's RSVP from this event
  Future<void> cancelRsvp(String eventId) async {
    try {
      await _apiClient.dio.delete('/events/$eventId/rsvp');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch attendee list — backend enforces event.update permission
  Future<List<Attendee>> getAttendees(String eventId) async {
    try {
      final response = await _apiClient.dio.get('/events/$eventId/attendees');
      final List<dynamic> data = response.data['data'];
      return data.map<Attendee>((json) => Attendee.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/event-categories');
      final List<dynamic> data = response.data['data'];
      return data.map<EventCategory>((json) => EventCategory.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Event> createEvent(Map<String, dynamic> data) async {
    try {
      final Map<String, dynamic> requestData = {
        'title': data['title'],
        'description': data['description'],
        'categoryId': data['categoryId'],
        'startDateTime': data['startDateTime'],
        'endDateTime': data['endDateTime'],
      };
      if (data['status'] != null) requestData['status'] = data['status'];
      if (data['coverImageId'] != null) requestData['coverImageId'] = data['coverImageId'];
      if (data['location'] != null) requestData['location'] = data['location'];
      if (data['locationUrl'] != null) requestData['locationUrl'] = data['locationUrl'];
      if (data['maxAttendees'] != null) requestData['maxAttendees'] = data['maxAttendees'];
      if (data['academicYearId'] != null) requestData['academicYearId'] = data['academicYearId'];

      final response = await _apiClient.dio.post('/events', data: requestData);
      return Event.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  // Legacy — kept for backward compat
  Future<void> rsvpToEvent(String eventId, String status) async {
    await _apiClient.dio.post('/events/$eventId/rsvp', data: {'status': status});
  }
}
