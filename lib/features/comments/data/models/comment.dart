class Comment {
  final String id;
  final String? parentId;
  final String authorId;
  final String authorName;
  final String content;
  final String? imageUrl;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Comment> children;

  Comment({
    required this.id,
    this.parentId,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.imageUrl,
    this.likeCount = 0,
    this.isLiked = false,
    required this.createdAt,
    required this.updatedAt,
    this.children = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Unknown',
      content: json['content']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      children: (json['children'] as List<dynamic>? ?? [])
          .map((c) => Comment.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  /// Total count of all descendants (for UI display)
  int get replyCount {
    int count = children.length;
    for (final child in children) {
      count += child.replyCount;
    }
    return count;
  }
}
