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
  final String? contactInfo;
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
    this.contactInfo,
    this.media = const [],
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    List<LostFoundMedia> parsedMedia = [];
    if (json['media'] is List) {
      parsedMedia.addAll((json['media'] as List).map((m) => LostFoundMedia.fromJson(
          m is Map ? Map<String, dynamic>.from(m) : {'id': m.toString(), 'url': ''})));
    }
    // Also check for various image fields for better compatibility
    if (json['coverImage'] is Map && parsedMedia.isEmpty) {
      parsedMedia.add(LostFoundMedia.fromJson(Map<String, dynamic>.from(json['coverImage'])));
    } else if (json['image'] is Map && parsedMedia.isEmpty) {
      parsedMedia.add(LostFoundMedia.fromJson(Map<String, dynamic>.from(json['image'])));
    } else if (json['imageUrl'] != null && parsedMedia.isEmpty) {
      parsedMedia.add(LostFoundMedia(id: 'cover', url: json['imageUrl'].toString()));
    } else if (json['image'] != null && json['image'] is String && parsedMedia.isEmpty) {
      parsedMedia.add(LostFoundMedia(id: 'cover', url: json['image'].toString()));
    } else if (json['coverImageUrl'] != null && parsedMedia.isEmpty) {
      parsedMedia.add(LostFoundMedia(id: 'cover', url: json['coverImageUrl'].toString()));
    }

    return LostFoundItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'LOST').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      location: (json['locationSeen'] ?? json['location'])?.toString(),
      dateLostFound: json['dateLostOrFound'] != null 
          ? DateTime.parse(json['dateLostOrFound'].toString()) 
          : (json['dateLostFound'] != null ? DateTime.parse(json['dateLostFound'].toString()) : null),
      isAnonymous: json['isAnonymous'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      reporter: json['reporter'] is Map 
          ? Reporter.fromJson(json['reporter']) 
          : Reporter(id: (json['reporterId'] ?? '').toString(), fullName: 'You'),
      category: json['category'] is Map 
          ? LostFoundCategory.fromJson(json['category']) 
          : (json['categoryId'] != null ? LostFoundCategory(id: json['categoryId'].toString(), name: '') : null),
      contactInfo: json['contactInfo']?.toString(),
      media: parsedMedia,
    );
  }
}

class Reporter {
  final String id;
  final String fullName;

  Reporter({required this.id, required this.fullName});

  factory Reporter.fromJson(Map<String, dynamic> json) {
    return Reporter(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'Unknown').toString(),
    );
  }
}

class LostFoundCategory {
  final String id;
  final String name;

  LostFoundCategory({required this.id, required this.name});

  factory LostFoundCategory.fromJson(Map<String, dynamic> json) {
    return LostFoundCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class LostFoundMedia {
  final String id;
  final String url;

  LostFoundMedia({required this.id, required this.url});

  factory LostFoundMedia.fromJson(Map<String, dynamic> json) {
    return LostFoundMedia(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
    );
  }
}
