import 'dart:convert';

class Announcement {
  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String type; // ANNOUNCEMENT, NOTICE, NEWS
  final String status; // DRAFT, PUBLISHED
  final bool isPinned;
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final Author author;
  final AnnouncementCategory? category;
  final CoverImage? coverImage;

  Announcement({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    required this.type,
    required this.status,
    this.isPinned = false,
    this.viewCount = 0,
    this.publishedAt,
    required this.createdAt,
    required this.author,
    this.category,
    this.coverImage,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      excerpt: json['excerpt'],
      content: json['content'],
      type: json['type'] ?? 'ANNOUNCEMENT',
      status: json['status'] ?? 'PUBLISHED',
      isPinned: json['isPinned'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      author: json['author'] != null 
          ? Author.fromJson(json['author']) 
          : Author(id: json['authorId'] ?? '', fullName: 'You'),
      category: json['category'] != null 
          ? AnnouncementCategory.fromJson(json['category']) 
          : (json['categoryId'] != null ? AnnouncementCategory(id: json['categoryId'], name: '') : null),
      coverImage: json['coverImage'] != null 
          ? CoverImage.fromJson(json['coverImage']) 
          : (json['coverImageId'] != null ? CoverImage(id: json['coverImageId'], url: '') : null),
    );
  }
}

class Author {
  final String id;
  final String fullName;

  Author({required this.id, required this.fullName});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? 'Unknown',
    );
  }
}

class AnnouncementCategory {
  final String id;
  final String name;

  AnnouncementCategory({required this.id, required this.name});

  factory AnnouncementCategory.fromJson(Map<String, dynamic> json) {
    return AnnouncementCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? 'General',
    );
  }
}

class CoverImage {
  final String id;
  final String url;

  CoverImage({required this.id, required this.url});

  factory CoverImage.fromJson(Map<String, dynamic> json) {
    return CoverImage(
      id: json['id'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
