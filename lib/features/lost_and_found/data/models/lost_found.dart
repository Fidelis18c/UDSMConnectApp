class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String type; // LOST, FOUND
  final String status; // OPEN, RESOLVED
  final String? location;
  final DateTime? dateLostFound;
  final bool isAnonymous;
  final DateTime createdAt;
  final Reporter reporter;
  final LostFoundCategory? category;
  final List<LostFoundMedia> media;

  LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.location,
    this.dateLostFound,
    this.isAnonymous = false,
    required this.createdAt,
    required this.reporter,
    this.category,
    this.media = const [],
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'LOST',
      status: json['status'] ?? 'OPEN',
      location: json['locationSeen'] ?? json['location'],
      dateLostFound: json['dateLostOrFound'] != null 
          ? DateTime.parse(json['dateLostOrFound']) 
          : (json['dateLostFound'] != null ? DateTime.parse(json['dateLostFound']) : null),
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      reporter: json['reporter'] != null 
          ? Reporter.fromJson(json['reporter']) 
          : Reporter(id: json['reporterId'] ?? '', fullName: 'You'),
      category: json['category'] != null 
          ? LostFoundCategory.fromJson(json['category']) 
          : (json['categoryId'] != null ? LostFoundCategory(id: json['categoryId'], name: '') : null),
      media: (json['media'] as List? ?? []).map((m) => LostFoundMedia.fromJson(m)).toList(),
    );
  }
}

class Reporter {
  final String id;
  final String fullName;

  Reporter({required this.id, required this.fullName});

  factory Reporter.fromJson(Map<String, dynamic> json) {
    return Reporter(
      id: json['id'],
      fullName: json['fullName'],
    );
  }
}

class LostFoundCategory {
  final String id;
  final String name;

  LostFoundCategory({required this.id, required this.name});

  factory LostFoundCategory.fromJson(Map<String, dynamic> json) {
    return LostFoundCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

class LostFoundMedia {
  final String id;
  final String url;

  LostFoundMedia({required this.id, required this.url});

  factory LostFoundMedia.fromJson(Map<String, dynamic> json) {
    return LostFoundMedia(
      id: json['id'],
      url: json['url'],
    );
  }
}
