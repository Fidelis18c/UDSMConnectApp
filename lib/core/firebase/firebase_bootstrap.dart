import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../core/navigation/notification_navigation.dart';
import '../../navigation/app_router.dart';
import 'package:firebase_core/firebase_core.dart';

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('FCM background message: ${message.messageId}');
  }
}

Future<void> bootstrapFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  FirebaseMessaging.onMessage.listen((message) {
    if (kDebugMode) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  final initial = await messaging.getInitialMessage();
  if (initial != null) {
    _handleNotificationNavigation(initial);
  }

  messaging.onTokenRefresh.listen((token) async {
    try {
      await NotificationRepository().registerToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token refresh register failed: $e');
    }
  });
}

Future<void> registerFcmTokenIfPossible() async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await NotificationRepository().registerToken(token);
    if (kDebugMode) debugPrint('FCM token registered with backend');
  } catch (e) {
    if (kDebugMode) debugPrint('FCM token register failed: $e');
  }
}

void _handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  final type = data['type'] as String?;
  final targetId = data['targetId'] as String?;
  if (type == null) return;

  final context = appRouter.routerDelegate.navigatorKey.currentContext;
  if (context == null) return;

  navigateFromNotification(context, type: type, targetId: targetId);
}
