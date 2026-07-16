import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:udsm_connect/core/navigation/notification_navigation.dart';
import 'package:udsm_connect/core/theme/app_colors.dart';
import 'package:udsm_connect/core/widgets/empty_state_widget.dart';
import 'package:udsm_connect/features/notifications/data/notification_repository.dart';
import 'package:udsm_connect/features/notifications/presentation/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(notificationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await ref.read(notificationsProvider.notifier).markAllRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator.adaptive(
              onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
              child: asyncItems.when(
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyStateWidget(
                          icon: Icons.notifications_none_outlined,
                          message: 'No notifications',
                        ),
                      ],
                    );
                  }

                  final unread = items.where((i) => !i.isRead).toList();
                  final read = items.where((i) => i.isRead).toList();

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Banner (Optional, placeholder like YouTube's "Turn on Notifications")
                      // _NotificationBanner(),

                      if (unread.isNotEmpty) ...[
                        _SectionHeader(title: 'Important'),
                        ...unread.map((item) => _NotificationCard(item: item)),
                      ],
                      
                      if (read.isNotEmpty) ...[
                        if (unread.isNotEmpty) Divider(height: 1, color: AppColors.divider),
                        _SectionHeader(title: 'Earlier'),
                        ...read.map((item) => _NotificationCard(item: item)),
                      ],
                      SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  Future<void> _handleTap(BuildContext context, WidgetRef ref) async {
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
    final typeIcon = notificationTypeIcon(item.type);
    final typeColor = notificationTypeColor(item.type);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _handleTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 8.0, 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Unread Dot Indicator
            SizedBox(
              width: 16,
              child: item.isRead
                  ? null
                  : const Center(
                      child: CircleAvatar(
                        radius: 3,
                        backgroundColor: AppColors.primary, // Blue dot like YouTube
                      ),
                    ),
            ),
            
            // Avatar / Icon
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: Icon(typeIcon, color: isDark ? Colors.white : Colors.black, size: 20),
            ),
            
            SizedBox(width: 12),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: isDark ? AppColors.textPrimary : Colors.black,
                        fontSize: 14,
                        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '${item.title}\n',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimary : Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: item.body,
                          style: TextStyle(
                            color: isDark ? (item.isRead ? AppColors.textSecondary : AppColors.textPrimary) : Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    timeago.format(item.sentAt),
                    style: TextStyle(
                      color: isDark ? AppColors.textHint : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: PhosphorIcon(PhosphorIconsBold.dotsThreeVertical, size: 20, color: isDark ? AppColors.textSecondary : Colors.black),
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onSelected: (value) {
                if (value == 'delete') {
                  ref.read(notificationsProvider.notifier).deleteNotification(item.id);
                }
              },
              itemBuilder: (context) {
                final itemColor = Theme.of(context).colorScheme.onSurface;
                return [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const PhosphorIcon(PhosphorIconsRegular.trash, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: itemColor)),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
