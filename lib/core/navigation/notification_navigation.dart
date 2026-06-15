import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/notification_type.dart';
import '../utils/story_grouping.dart';
import '../../features/lost_and_found/data/repositories/lost_found_repository.dart';
import '../../features/stories/data/repositories/story_repository.dart';
import '../../navigation/route_names.dart';

/// Deep-link from in-app inbox or FCM tap into the correct screen.
Future<void> navigateFromNotification(
  BuildContext context, {
  required String type,
  String? targetId,
}) async {
  final normalized = NotificationTypes.normalize(type);

  switch (normalized) {
    case NotificationTypes.post:
    case NotificationTypes.announcement:
      if (targetId == null) return;
      await context.pushNamed(
        RouteNames.postDetail,
        pathParameters: {'id': targetId},
      );
    case NotificationTypes.feedback:
      context.goNamed(RouteNames.feedback);
    case NotificationTypes.lostFound:
      if (targetId == null) return;
      try {
        final item = await LostFoundRepository().getItemDetail(targetId);
        if (!context.mounted) return;
        await context.pushNamed(
          RouteNames.lostFoundDetail,
          pathParameters: {'id': targetId},
          extra: item,
        );
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open lost & found item.')),
        );
      }
    case NotificationTypes.story:
      if (targetId == null) return;
      try {
        final stories = await StoryRepository().fetchStories();
        final groups = groupStoriesByCollege(stories);
        if (groups.isEmpty) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story is no longer available.')),
          );
          return;
        }
        if (!context.mounted) return;
        await context.pushNamed(
          RouteNames.storyViewer,
          extra: buildStoryViewerArgs(groups, targetId),
        );
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open story.')),
        );
      }
    default:
      break;
  }
}

IconData notificationTypeIcon(String type) {
  switch (NotificationTypes.normalize(type)) {
    case NotificationTypes.story:
      return Icons.auto_stories_outlined;
    case NotificationTypes.announcement:
      return Icons.campaign_outlined;
    case NotificationTypes.lostFound:
      return Icons.inventory_2_outlined;
    case NotificationTypes.feedback:
      return Icons.chat_bubble_outline;
    case NotificationTypes.post:
    default:
      return Icons.newspaper_outlined;
  }
}

Color notificationTypeColor(String type) {
  switch (NotificationTypes.normalize(type)) {
    case NotificationTypes.story:
      return Colors.purple;
    case NotificationTypes.announcement:
      return Colors.teal;
    case NotificationTypes.lostFound:
      return Colors.amber.shade800;
    case NotificationTypes.feedback:
      return Colors.green;
    case NotificationTypes.post:
    default:
      return Colors.blue;
  }
}

String notificationFilterLabel(NotificationFilter filter) {
  return switch (filter) {
    NotificationFilter.all => 'All',
    NotificationFilter.posts => 'Posts',
    NotificationFilter.announcements => 'Announcements',
    NotificationFilter.stories => 'Stories',
    NotificationFilter.lostFound => 'Lost & Found',
    NotificationFilter.feedbacks => 'Feedback',
  };
}

enum NotificationFilter { all, posts, announcements, stories, lostFound, feedbacks }

String? notificationFilterType(NotificationFilter filter) {
  return switch (filter) {
    NotificationFilter.all => null,
    NotificationFilter.posts => NotificationTypes.post,
    NotificationFilter.announcements => NotificationTypes.announcement,
    NotificationFilter.stories => NotificationTypes.story,
    NotificationFilter.lostFound => NotificationTypes.lostFound,
    NotificationFilter.feedbacks => NotificationTypes.feedback,
  };
}