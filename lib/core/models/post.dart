class Post {
  final String id;
  final String authorName;
  final String? authorProfilePic;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final int likes;
  final bool isLiked;
  final String category; // e.g., 'Class', 'Academics', 'Lost and Found'

  Post({
    required this.id,
    required this.authorName,
    this.authorProfilePic,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    this.category = 'All updates',
  });

  Post copyWith({
    String? id,
    String? authorName,
    String? authorProfilePic,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    int? likes,
    bool? isLiked,
    String? category,
  }) {
    return Post(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorProfilePic: authorProfilePic ?? this.authorProfilePic,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      category: category ?? this.category,
    );
  }
}
