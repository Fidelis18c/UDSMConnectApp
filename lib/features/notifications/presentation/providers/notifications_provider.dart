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
