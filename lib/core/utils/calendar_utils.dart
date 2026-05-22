import 'package:url_launcher/url_launcher.dart';
import '../models/event.dart';

class CalendarUtils {
  CalendarUtils._();

  /// Format a DateTime to Google Calendar's required format: YYYYMMDDTHHmmssZ (UTC)
  static String _formatDate(DateTime dt) {
    final utc = dt.toUtc();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${utc.year}'
        '${pad(utc.month)}'
        '${pad(utc.day)}'
        'T'
        '${pad(utc.hour)}'
        '${pad(utc.minute)}'
        '${pad(utc.second)}'
        'Z';
  }

  /// Builds the Google Calendar pre-fill URL for a given event.
  static Uri buildGoogleCalendarUri(Event event) {
    final start = _formatDate(event.startDateTime);
    final end = _formatDate(event.endDateTime);

    return Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': event.title,
      'dates': '$start/$end',
      'details': event.description,
      'location': event.location,
    });
  }

  /// Opens Google Calendar with the event pre-filled.
  /// Returns true if launched successfully, false otherwise.
  static Future<bool> addToGoogleCalendar(Event event) async {
    final uri = buildGoogleCalendarUri(event);
    try {
      // launchUrl returns true if successfully launched. 
      // Bypassing canLaunchUrl avoids requiring <queries> in AndroidManifest.xml
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
