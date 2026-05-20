class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String type; // LOST | FOUND
  final String status; // OPEN | RESOLVED
  final String? location;
  final DateTime? dateLostFound;
  final bool isAnonymous;
  final DateTime createdAt;
  final Reporter? reporter;
  final LostFoundCategory? category;
  final String? contactInfo;
  final LostFoundMedia? coverImage; // first image (from feed endpoint)
  final List<LostFoundMedia> media;  // all images (from detail endpoint)

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
    this.reporter,
    this.category,
    this.contactInfo,
    this.coverImage,
    this.media = const [],
  });

  /// Convenience — best image URL to show anywhere
  String? get displayImageUrl =>
      coverImage?.url ?? (media.isNotEmpty ? media.first.url : null);

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    // Parse full media array (detail endpoint)
    List<LostFoundMedia> parsedMedia = [];
    if (json['media'] is List) {
      parsedMedia = (json['media'] as List)
          .map((m) => LostFoundMedia.fromJson(
              m is Map ? Map<String, dynamic>.from(m) : {'id': m.toString(), 'url': ''}))
          .toList();
    }

    // Parse single coverImage (feed endpoint)
    LostFoundMedia? coverImage;
    if (json['coverImage'] is Map) {
      coverImage = LostFoundMedia.fromJson(Map<String, dynamic>.from(json['coverImage']));
    }

    // Reporter — may be null if anonymous
    Reporter? reporter;
    if (json['reporter'] is Map) {
      reporter = Reporter.fromJson(Map<String, dynamic>.from(json['reporter']));
    } else if (json['reporterId'] != null) {
      reporter = Reporter(id: json['reporterId'].toString(), fullName: 'You');
    }

    return LostFoundItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      type: (json['type'] ?? 'LOST').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      location: (json['locationSeen'] ?? json['location'])?.toString(),
      dateLostFound: json['dateLostOrFound'] != null
          ? DateTime.tryParse(json['dateLostOrFound'].toString())
          : json['dateLostFound'] != null
              ? DateTime.tryParse(json['dateLostFound'].toString())
              : null,
      isAnonymous: json['isAnonymous'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reporter: reporter,
      category: json['category'] is Map
          ? LostFoundCategory.fromJson(Map<String, dynamic>.from(json['category']))
          : null,
      contactInfo: json['contactInfo']?.toString(),
      coverImage: coverImage,
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
