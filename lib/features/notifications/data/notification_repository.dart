import '../../../../core/network/api_client.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime sentAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.targetType,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      targetId: json['targetId'] as String?,
      targetType: json['targetType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

class NotificationListResult {
  final List<NotificationItem> items;
  final int unreadCount;
  final int total;

  NotificationListResult({
    required this.items,
    required this.unreadCount,
    required this.total,
  });
}

class NotificationRepository {
  final ApiClient _api = ApiClient();

  Future<void> registerToken(String fcmToken, {String deviceType = 'ANDROID'}) async {
    await _api.dio.post(
      '/notifications/token',
      data: {'fcmToken': fcmToken, 'deviceType': deviceType},
    );
  }

  Future<NotificationListResult> fetchNotifications({int page = 1, int pageSize = 30}) async {
    final response = await _api.dio.get(
      '/notifications',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>? ?? [])
        .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    return NotificationListResult(
      items: list,
      unreadCount: meta['unreadCount'] as int? ?? 0,
      total: meta['total'] as int? ?? list.length,
    );
  }

  Future<int> fetchUnreadCount() async {
    final result = await fetchNotifications(page: 1, pageSize: 1);
    return result.unreadCount;
  }

  Future<void> markRead(String id) async {
    await _api.dio.put('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.dio.put('/notifications/read-all');
  }

  Future<bool> getPostsPreference() async {
    final response = await _api.dio.get('/notifications/preferences');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return data['posts'] as bool? ?? true;
  }

  Future<void> setPostsPreference(bool enabled) async {
    await _api.dio.put('/notifications/preferences', data: {'posts': enabled});
  }
}
