/// Canonical notification types — keep in sync with backend `NOTIFICATION_TYPES`.
class NotificationTypes {
  static const post = 'POST';
  static const story = 'STORY';
  static const announcement = 'ANNOUNCEMENT';
  static const lostFound = 'LOST_FOUND';
  static const feedback = 'FEEDBACK';

  /// Normalizes legacy lowercase values from older inbox rows.
  static String normalize(String type) {
    switch (type.toUpperCase()) {
      case 'POST':
        return post;
      case 'STORY':
        return story;
      case 'ANNOUNCEMENT':
        return announcement;
      case 'LOST_FOUND':
        return lostFound;
      case 'FEEDBACK':
        return feedback;
      default:
        return type;
    }
  }
}