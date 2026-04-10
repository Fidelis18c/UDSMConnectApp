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
}
