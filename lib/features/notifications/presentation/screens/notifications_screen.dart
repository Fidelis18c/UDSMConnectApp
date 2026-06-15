import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final asyncItems = ref.watch(filteredNotificationsProvider);
    
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
          const _FilterChips(),
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
                        const _SectionHeader(title: 'Important'),
                        ...unread.map((item) => _NotificationCard(item: item)),
                      ],
                      
                      if (read.isNotEmpty) ...[
                        if (unread.isNotEmpty) const Divider(height: 1, color: AppColors.divider),
                        const _SectionHeader(title: 'Earlier'),
                        ...read.map((item) => _NotificationCard(item: item)),
                      ],
                      const SizedBox(height: 80),
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

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(notificationFilterProvider);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = filter == currentFilter;
          final title = notificationFilterLabel(filter);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              label: Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.background : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selectedColor: AppColors.textPrimary, // White when selected
              backgroundColor: AppColors.chipUnselected, // Dark grey when not
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              onSelected: (_) {
                ref.read(notificationFilterProvider.notifier).setFilter(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
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
    
    return InkWell(
      onTap: () => _handleTap(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              backgroundColor: typeColor.withOpacity(0.1),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            
            const SizedBox(width: 12),
            
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
                        fontFamily: 'Roboto', // YouTube style
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w600,
                      ),
                      children: [
                        TextSpan(text: '${item.title}\n'),
                        TextSpan(
                          text: item.body,
                          style: TextStyle(
                            color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeago.format(item.sentAt),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Right-side visual / Action (Like the video thumbnail, we use a tinted box)
            Container(
              width: 50,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Icon(typeIcon, color: typeColor.withOpacity(0.8), size: 18),
              ),
            ),
            
            // 3-dot menu
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                // Future: show menu (mark read, turn off, etc)
              },
            ),
          ],
        ),
      ),
    );
  }
}
