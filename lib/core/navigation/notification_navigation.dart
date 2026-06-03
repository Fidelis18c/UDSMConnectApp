import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/events/data/repositories/event_repository.dart';
import '../../navigation/route_names.dart';

/// Deep-link from in-app inbox or FCM tap into the correct screen.
Future<void> navigateFromNotification(
  BuildContext context, {
  required String type,
  String? targetId,
}) async {
  switch (type) {
    case 'POST':
      if (targetId == null) return;
      await context.pushNamed(
        RouteNames.postDetail,
        pathParameters: {'id': targetId},
      );
    case 'EVENT':
      if (targetId == null) return;
      try {
        final event = await EventRepository().getEventDetails(targetId);
        if (!context.mounted) return;
        await context.pushNamed(
          RouteNames.eventDetail,
          pathParameters: {'id': targetId},
          extra: event,
        );
      } catch (_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open event.')),
        );
      }
    case 'FEEDBACK':
      context.goNamed(RouteNames.feedback);
    default:
      break;
  }
}

IconData notificationTypeIcon(String type) {
  switch (type) {
    case 'EVENT':
      return Icons.event_outlined;
    case 'FEEDBACK':
      return Icons.chat_bubble_outline;
    case 'POST':
    default:
      return Icons.newspaper_outlined;
  }
}

Color notificationTypeColor(String type) {
  switch (type) {
    case 'EVENT':
      return Colors.orange;
    case 'FEEDBACK':
      return Colors.green;
    case 'POST':
    default:
      return Colors.blue;
  }
}
