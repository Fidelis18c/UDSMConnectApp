import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/features/notifications/data/notification_repository.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

class NotificationsNotifier extends AsyncNotifier<List<NotificationItem>> {
  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  int unreadCount = 0;

  @override
  Future<List<NotificationItem>> build() async {
    final result = await _repo.fetchNotifications();
    unreadCount = result.unreadCount;
    return result.items;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.fetchNotifications();
      unreadCount = result.unreadCount;
      return result.items;
    });
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    await refresh();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
  NotificationsNotifier.new,
);

final unreadCountProvider = FutureProvider<int>((ref) async {
  ref.watch(notificationsProvider);
  return ref.read(notificationRepositoryProvider).fetchUnreadCount();
});

enum NotificationFilter { all, feedbacks, posts, events }

class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => NotificationFilter.all;

  void setFilter(NotificationFilter filter) {
    state = filter;
  }
}

final notificationFilterProvider = NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
  NotificationFilterNotifier.new,
);

final filteredNotificationsProvider = Provider<AsyncValue<List<NotificationItem>>>((ref) {
  final allNotificationsAsync = ref.watch(notificationsProvider);
  final filter = ref.watch(notificationFilterProvider);

  return allNotificationsAsync.whenData((items) {
    if (filter == NotificationFilter.all) return items;
    
    final typeMatch = switch (filter) {
      NotificationFilter.feedbacks => 'FEEDBACK',
      NotificationFilter.posts => 'POST',
      NotificationFilter.events => 'EVENT',
      _ => '',
    };
    
    return items.where((item) => item.type == typeMatch).toList();
  });
});
