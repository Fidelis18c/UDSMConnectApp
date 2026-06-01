import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:udsm_connect/core/navigation/notification_navigation.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/features/notifications/data/notification_repository.dart';
import 'package:udsm_connect/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    await navigateFromNotification(
      context,
      type: item.type,
      targetId: item.targetId,
    );
    if (!context.mounted) return;
    if (!item.isRead) {
      await ref.read(notificationsProvider.notifier).markRead(item.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: asyncItems.when(
          loading: () => const Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2.5),
            ),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyStateWidget(
                    icon: Icons.notifications_none_outlined,
                    message: 'No notifications yet',
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final item = items[index];
                final iconData = notificationTypeIcon(item.type);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.isRead
                        ? AppColors.chipUnselected
                        : AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(
                      iconData,
                      color: item.isRead ? AppColors.textSecondary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: item.isRead
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                  onTap: () => _openNotification(context, ref, item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
