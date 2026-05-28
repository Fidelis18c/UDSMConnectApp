class StoryMedia {
  final String id;
  final String url;
  final String type;

  StoryMedia({required this.id, required this.url, required this.type});

  factory StoryMedia.fromJson(Map<String, dynamic> json) {
    return StoryMedia(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
    );
  }
}

class StoryAuthor {
  final String id;
  final String fullName;

  StoryAuthor({required this.id, required this.fullName});

  factory StoryAuthor.fromJson(Map<String, dynamic> json) {
    return StoryAuthor(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
    );
  }
}

class StoryCollege {
  final String id;
  final String name;
  final String shortName;

  StoryCollege({
    required this.id,
    required this.name,
    required this.shortName,
  });

  factory StoryCollege.fromJson(Map<String, dynamic> json) {
    return StoryCollege(
      id: json['id'] as String,
      name: json['name'] as String,
      shortName: json['shortName'] as String,
    );
  }
}

class Story {
  final String id;
  final String? caption;
  final String? backgroundColor;
  final String? linkUrl;
  final String? linkText;
  final int viewCount;
  final DateTime expiresAt;
  final DateTime createdAt;
  final bool hasViewed;
  final StoryAuthor author;
  final StoryCollege? college;
  final StoryMedia? media;

  Story({
    required this.id,
    this.caption,
    this.backgroundColor,
    this.linkUrl,
    this.linkText,
    required this.viewCount,
    required this.expiresAt,
    required this.createdAt,
    required this.hasViewed,
    required this.author,
    this.college,
    this.media,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      caption: json['caption'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      linkUrl: json['linkUrl'] as String?,
      linkText: json['linkText'] as String?,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      hasViewed: json['hasViewed'] as bool? ?? false,
      author: StoryAuthor.fromJson(json['author'] as Map<String, dynamic>),
      college: json['college'] != null
          ? StoryCollege.fromJson(json['college'] as Map<String, dynamic>)
          : null,
      media: json['media'] != null
          ? StoryMedia.fromJson(json['media'] as Map<String, dynamic>)
          : null,
    );
  }

  Story copyWith({
    bool? hasViewed,
    int? viewCount,
  }) {
    return Story(
      id: id,
      caption: caption,
      backgroundColor: backgroundColor,
      linkUrl: linkUrl,
      linkText: linkText,
      viewCount: viewCount ?? this.viewCount,
      expiresAt: expiresAt,
      createdAt: createdAt,
      hasViewed: hasViewed ?? this.hasViewed,
      author: author,
      college: college,
      media: media,
    );
  }
}
