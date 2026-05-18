class Event {
  final String id;
  final String title;
  final String description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String location;
  final String? locationUrl;
  final int? maxAttendees;
  final String status;
  final String? imageUrl;
  final String organizer;
  final String? organizerId;
  final String? categoryName;
  final int goingCount;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.location,
    this.locationUrl,
    this.maxAttendees,
    required this.status,
    this.imageUrl,
    required this.organizer,
    this.organizerId,
    this.categoryName,
    this.goingCount = 0,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      startDateTime: json['startDateTime'] != null 
          ? DateTime.parse(json['startDateTime'].toString()) 
          : DateTime.now(),
      endDateTime: json['endDateTime'] != null 
          ? DateTime.parse(json['endDateTime'].toString()) 
          : DateTime.now().add(const Duration(hours: 1)),
      location: (json['location'] ?? 'TBA').toString(),
      locationUrl: json['locationUrl']?.toString(),
      maxAttendees: json['maxAttendees'] != null ? int.tryParse(json['maxAttendees'].toString()) : null,
      status: (json['status'] ?? 'PUBLISHED').toString(),
      imageUrl: json['coverImage'] is Map ? json['coverImage']['url']?.toString() : null,
      organizer: json['organizer'] is Map ? (json['organizer']['fullName'] ?? 'Unknown').toString() : 'Unknown',
      organizerId: json['organizer'] is Map ? json['organizer']['id']?.toString() : null,
      categoryName: json['category'] is Map ? (json['category']['name'] ?? '').toString() : null,
      goingCount: (json['goingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class EventCategory {
  final String id;
  final String name;
  final String? iconName;

  EventCategory({
    required this.id,
    required this.name,
    this.iconName,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      iconName: json['iconName']?.toString(),
    );
  }
}
