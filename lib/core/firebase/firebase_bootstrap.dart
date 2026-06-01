import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../firebase_options.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../navigation/notification_navigation.dart';
import '../../navigation/app_router.dart';

/// Android channel for heads-up popups (foreground local + FCM default).
const String highImportanceChannelId = 'high_importance_channel';
const String highImportanceChannelName = 'New notifications';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsInitialized = false;

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLocalNotifications();
  // FCM shows notification payload in tray when backgrounded; only mirror data-only messages.
  if (message.notification == null) {
    await showForegroundLocalNotification(message);
  }
}

Future<void> initLocalNotifications() async {
  if (_localNotificationsInitialized) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: _onLocalNotificationTap,
  );

  const channel = AndroidNotificationChannel(
    highImportanceChannelId,
    highImportanceChannelName,
    description: 'Post, event, and feedback alerts',
    importance: Importance.max,
  );

  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(channel);

  _localNotificationsInitialized = true;
}

void _onLocalNotificationTap(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  try {
    final map = jsonDecode(payload) as Map<String, dynamic>;
    final type = map['type'] as String?;
    if (type == null) return;

    final targetId = map['targetId'] as String?;
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;

    navigateFromNotification(context, type: type, targetId: targetId);
  } catch (e) {
    if (kDebugMode) debugPrint('Local notification tap parse failed: $e');
  }
}

Future<void> bootstrapFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLocalNotifications();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen(showForegroundLocalNotification);

  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    _handleNotificationNavigation(initial);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    try {
      await NotificationRepository().registerToken(token);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token refresh register failed: $e');
    }
  });
}

/// Request POST_NOTIFICATIONS after the first frame (Activity resumed).
Future<void> ensureNotificationPermission() async {
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidImpl != null) {
    await androidImpl.requestNotificationsPermission();
  }

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
}

Future<void> showForegroundLocalNotification(RemoteMessage message) async {
  await initLocalNotifications();

  final notification = message.notification;
  final title = notification?.title ?? 'Notification';
  final body = notification?.body ?? '';

  final type = message.data['type'] as String? ?? '';
  final targetId = message.data['targetId'] as String?;

  final payload = jsonEncode({
    'type': type,
    if (targetId != null && targetId.isNotEmpty) 'targetId': targetId,
  });

  const androidDetails = AndroidNotificationDetails(
    highImportanceChannelId,
    highImportanceChannelName,
    channelDescription: 'Post, event, and feedback alerts',
    importance: Importance.max,
    priority: Priority.high,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    const NotificationDetails(android: androidDetails),
    payload: payload,
  );
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
