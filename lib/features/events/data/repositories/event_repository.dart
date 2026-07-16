import 'package:dio/dio.dart';
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
        'description': (data['description'] as String?)?.trim().isNotEmpty == true
            ? data['description']
            : 'No description provided.',
        'categoryId': data['categoryId'],
        'startDateTime': data['startDateTime'],
        'endDateTime': data['endDateTime'],
      };
      if (data['status'] != null) requestData['status'] = data['status'];
      if (data['coverImageId'] != null &&
          data['coverImageId'].toString().isNotEmpty) {
        requestData['coverImageId'] = data['coverImageId'];
      }
      final loc = (data['location'] as String?)?.trim();
      if (loc != null && loc.isNotEmpty) requestData['location'] = loc;
      final locUrl = (data['locationUrl'] as String?)?.trim();
      if (locUrl != null && locUrl.isNotEmpty) {
        requestData['locationUrl'] = locUrl;
      }
      if (data['maxAttendees'] != null) {
        requestData['maxAttendees'] = data['maxAttendees'];
      }
      if (data['academicYearId'] != null &&
          data['academicYearId'].toString().isNotEmpty) {
        requestData['academicYearId'] = data['academicYearId'];
      }

      final response = await _apiClient.dio.post('/events', data: requestData);
      final payload = response.data['data'];
      if (payload is Map<String, dynamic>) {
        return Event.fromJson(payload);
      }
      return Event.fromJson(Map<String, dynamic>.from(payload as Map));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString())
          : null;
      throw Exception(msg ?? 'Failed to create event (${e.response?.statusCode ?? 'network'})');
    } catch (e) {
      rethrow;
    }
  }

  // Legacy — kept for backward compat
  Future<void> rsvpToEvent(String eventId, String status) async {
    await _apiClient.dio.post('/events/$eventId/rsvp', data: {'status': status});
  }
}
