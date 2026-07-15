class Post {
  /// Announcement headline from the API (optional for legacy local drafts).
  final String title;

  final String id;
  final String authorId;
  final String authorName;
  final String? authorProfilePic;

  /// Raw role name from the API author object (e.g. "Class representative", "Daruso leader").
  final String? authorRole;

  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final int likes;
  final int commentCount;
  final bool isLiked;
  final String category;

  /// True when surfaced from API as pinned announcement.
  final bool isPinned;

  Post({
    this.title = '',
    required this.id,
    this.authorId = '',
    required this.authorName,
    this.authorProfilePic,
    this.authorRole,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.likes = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.category = 'All updates',
    this.isPinned = false,
  });

  /// Lower rank = more prominent badge (student last / ignored).
  static int _rolePriority(String name) {
    final x = name.toLowerCase().replaceAll('_', ' ').trim();
    if (x == 'admin' || x == 'super admin' || x.contains('super admin')) return 0;
    if (x.contains('daruso') || x.contains('college rep') || x.contains('college leader')) {
      return 1;
    }
    if (x.contains('class representative') || x.contains('class rep') || x == 'cr') {
      return 2;
    }
    if (x.contains('lecturer')) return 3;
    if (x == 'staff' || x.contains('department staff')) return 4;
    if (x.contains('sports')) return 5;
    if (x == 'student' || x.isEmpty) return 100;
    return 50;
  }

  /// Picks the most prominent non-student role from the author's roles array.
  static String? _extractAuthorRole(Map<String, dynamic>? author) {
    if (author == null) return null;
    final names = <String>[];
    final roles = author['roles'] as List<dynamic>?;
    if (roles != null) {
      for (final r in roles) {
        if (r is Map<String, dynamic>) {
          final name = (r['name'] as String?)?.trim() ?? '';
          if (name.isNotEmpty) names.add(name);
        } else if (r is String && r.trim().isNotEmpty) {
          names.add(r.trim());
        }
      }
    }
    final single = author['roleName'] as String?
        ?? (author['role'] is Map
            ? (author['role'] as Map<String, dynamic>)['name'] as String?
            : author['role'] as String?);
    if (single != null && single.trim().isNotEmpty) names.add(single.trim());

    if (names.isEmpty) return null;
    names.sort((a, b) => _rolePriority(a).compareTo(_rolePriority(b)));
    final best = names.first;
    if (_rolePriority(best) >= 100) return null;
    return best;
  }

  String get subtitleHandle {
    final c = category.trim();
    if (c.isEmpty) return '@updates';
    if (c.startsWith('@')) return c;
    return '@$c';
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  factory Post.fromAnnouncementListJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final categoryMap = json['category'] as Map<String, dynamic>?;
    final cover = json['coverImage'] as Map<String, dynamic>?;
    final published = json['publishedAt'] ?? json['createdAt'];
    final excerpt = json['excerpt'] as String?;
    final title = (json['title'] as String?)?.trim() ?? '';

    String body;
    if (excerpt != null && excerpt.trim().isNotEmpty) {
      body = excerpt.trim();
    } else {
      body = '';
    }
    // Never repeat the title as the body.
    if (body == title) body = '';

    return Post(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? '',
      title: title,
      authorName: author?['fullName'] as String? ?? 'Unknown',
      authorProfilePic: author?['avatarUrl'] as String?,
      authorRole: _extractAuthorRole(author),
      text: body,
      imageUrl: cover?['url'] as String?,
      timestamp: _parseDate(published),
      likes: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      category: categoryMap?['name'] as String? ?? 'Updates',
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  factory Post.fromAnnouncementDetailJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final categoryMap = json['category'] as Map<String, dynamic>?;
    final cover = json['coverImage'] as Map<String, dynamic>?;
    final published = json['publishedAt'] ?? json['createdAt'];
    final title = (json['title'] as String?)?.trim() ?? '';
    final content = (json['content'] as String?)?.trim();
    final excerpt = (json['excerpt'] as String?)?.trim();

    String body;
    if (content != null && content.isNotEmpty) {
      body = content;
    } else if (excerpt != null && excerpt.isNotEmpty) {
      body = excerpt;
    } else {
      body = '';
    }
    // Never repeat the title as the body.
    if (body == title) body = '';

    String? imageUrl = cover?['url'] as String?;
    final mediaItems = json['media'] as List<dynamic>?;
    if ((imageUrl == null || imageUrl.isEmpty) && mediaItems != null && mediaItems.isNotEmpty) {
      final first = mediaItems.first;
      if (first is Map<String, dynamic>) {
        imageUrl = first['url'] as String?;
      }
    }

    return Post(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? '',
      title: title,
      authorName: author?['fullName'] as String? ?? 'Unknown',
      authorProfilePic: author?['avatarUrl'] as String?,
      authorRole: _extractAuthorRole(author),
      text: body,
      imageUrl: imageUrl,
      timestamp: _parseDate(published),
      likes: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      category: categoryMap?['name'] as String? ?? 'Updates',
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  factory Post.fromPostsListJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final published = json['publishedAt'] ?? json['createdAt'];
    final rawTitle = (json['title'] as String?)?.trim() ?? '';
    final rawContent = (json['content'] as String?)?.trim() ?? '';
    final typeLabel = (json['type'] as String?)?.trim();
    final categoryTag = typeLabel != null && typeLabel.isNotEmpty ? typeLabel : 'Post';

    final plain = rawContent.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    String body;
    if (plain.isNotEmpty) {
      body = plain.length > 340 ? '${plain.substring(0, 340)}…' : plain;
    } else {
      body = rawTitle;
    }

    String? imageUrl;
    
    final rawMedia = json['media'];
    if (rawMedia is List && rawMedia.isNotEmpty) {
      final first = rawMedia.first;
      if (first is Map<String, dynamic>) {
        imageUrl = first['url'] as String?;
      }
    } else if (rawMedia is Map<String, dynamic>) {
      imageUrl = rawMedia['url'] as String?;
    }
    
    if (imageUrl == null || imageUrl.isEmpty) {
      final cover = json['coverImage'] as Map<String, dynamic>?;
      imageUrl = cover?['url'] as String?;
    }
    
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json['coverImageUrl'] as String?;
    }

    return Post(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? '',
      title: rawTitle,
      authorName: author?['fullName'] as String? ?? 'Unknown',
      authorProfilePic: author?['avatarUrl'] as String?,
      authorRole: _extractAuthorRole(author),
      text: body,
      imageUrl: imageUrl,
      timestamp: _parseDate(published),
      likes: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      category: categoryTag,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  factory Post.fromPostsDetailJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final published = json['publishedAt'] ?? json['createdAt'];
    final rawTitle = (json['title'] as String?)?.trim() ?? '';
    final rawContent = (json['content'] as String?)?.trim() ?? '';
    final typeLabel = (json['type'] as String?)?.trim();
    final categoryTag = typeLabel != null && typeLabel.isNotEmpty ? typeLabel : 'Post';

    final body = rawContent.isNotEmpty ? rawContent : rawTitle;

    String? imageUrl;
    
    final rawMedia = json['media'];
    if (rawMedia is List && rawMedia.isNotEmpty) {
      final first = rawMedia.first;
      if (first is Map<String, dynamic>) {
        imageUrl = first['url'] as String?;
      }
    } else if (rawMedia is Map<String, dynamic>) {
      imageUrl = rawMedia['url'] as String?;
    }
    
    if (imageUrl == null || imageUrl.isEmpty) {
      final cover = json['coverImage'] as Map<String, dynamic>?;
      imageUrl = cover?['url'] as String?;
    }

    return Post(
      id: json['id'] as String,
      authorId: author?['id'] as String? ?? '',
      title: rawTitle.isNotEmpty ? rawTitle : (body.length > 80 ? '${body.substring(0, 80)}…' : body),
      authorName: author?['fullName'] as String? ?? 'Unknown',
      authorProfilePic: author?['avatarUrl'] as String?,
      authorRole: _extractAuthorRole(author),
      text: body,
      imageUrl: imageUrl,
      timestamp: _parseDate(published),
      likes: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      category: categoryTag,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Post copyWith({
    String? title,
    String? id,
    String? authorId,
    String? authorName,
    String? authorProfilePic,
    String? authorRole,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    int? likes,
    int? commentCount,
    bool? isLiked,
    String? category,
    bool? isPinned,
  }) {
    return Post(
      title: title ?? this.title,
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorProfilePic: authorProfilePic ?? this.authorProfilePic,
      authorRole: authorRole ?? this.authorRole,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
