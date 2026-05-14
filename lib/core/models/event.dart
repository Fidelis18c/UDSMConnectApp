class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String? imageUrl;
  final String organizer;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    this.imageUrl,
    required this.organizer,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      date: json['startDateTime'] != null 
          ? DateTime.parse(json['startDateTime'].toString()) 
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now()),
      location: (json['location'] ?? 'TBA').toString(),
      imageUrl: json['coverImage'] is Map ? json['coverImage']['url']?.toString() : null,
      organizer: json['organizer'] is Map ? (json['organizer']['fullName'] ?? 'Unknown').toString() : 'Unknown',
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
