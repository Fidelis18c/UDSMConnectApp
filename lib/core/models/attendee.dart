class Attendee {
  final String id;
  final String userId;
  final String userName;
  final String email;
  final String status;
  final DateTime createdAt;

  Attendee({
    required this.id,
    required this.userId,
    required this.userName,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory Attendee.fromJson(Map<String, dynamic> json) {
    return Attendee(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? 'Unknown').toString(),
      email: (json['email'] ?? '').toString(),
      status: (json['status'] ?? 'GOING').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }
}
