import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../navigation/notification_navigation.dart';
import '../notifications/notification_events.dart';
import '../../navigation/app_router.dart';

/// Heads-up channel id — must match backend FCM `android.notification.channelId`.
///
/// Versioned (`_v2`) because Android never upgrades importance of an existing
/// channel. If the old id was created without MAX importance, popups never show.
const String highImportanceChannelId = 'udsm_alerts_v2';
const String highImportanceChannelName = 'UDSM Alerts';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsInitialized = false;

/// Background FCM handler (must be top-level).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLocalNotifications();
  // When FCM includes a `notification` payload, Android already posts it.
  // For data-only messages, show a local heads-up ourselves.
  if (message.notification == null) {
    await showLocalNotificationFromRemote(message);
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

  // MAX importance + sound/vibration → eligible for heads-up banner.
  const channel = AndroidNotificationChannel(
    highImportanceChannelId,
    highImportanceChannelName,
    description: 'Urgent campus alerts: posts, announcements, feedback',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidImpl?.createNotificationChannel(channel);

  _localNotificationsInitialized = true;
  if (kDebugMode) {
    debugPrint('Local notifications ready (channel=$highImportanceChannelId)');
  }
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

  // High priority so OS delivers promptly (needed for heads-up eligibility).
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((message) async {
    if (kDebugMode) {
      debugPrint(
        'FCM foreground: title=${message.notification?.title} data=${message.data}',
      );
    }
    // App open: system will NOT auto-show — we must post a local heads-up.
    await showLocalNotificationFromRemote(message);
    requestUnreadRefresh();
  });

  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) {
    _handleNotificationNavigation(initial);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('auth_token');
    if (storedToken == null || storedToken.isEmpty) return;
    try {
      await NotificationRepository().registerToken(token);
      if (kDebugMode) debugPrint('FCM token refreshed and re-registered');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token refresh register failed: $e');
    }
  });
}

/// Request POST_NOTIFICATIONS after the first frame (Activity resumed).
Future<void> ensureNotificationPermission() async {
  final androidImpl = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Android 13+ runtime notification permission.
  final granted = await androidImpl?.requestNotificationsPermission();
  if (kDebugMode) {
    debugPrint('POST_NOTIFICATIONS granted=$granted');
  }

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
  );
  if (kDebugMode) {
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  // Ensure channel exists even if bootstrap order changes.
  await initLocalNotifications();
}

/// Show a heads-up style local notification from an FCM [RemoteMessage].
Future<void> showLocalNotificationFromRemote(RemoteMessage message) async {
  await initLocalNotifications();

  final notification = message.notification;
  final title = notification?.title ??
      message.data['title'] ??
      'UDSM Connect';
  final body = notification?.body ??
      message.data['body'] ??
      '';

  final type = message.data['type'] as String? ?? '';
  final targetId = message.data['targetId'] as String?;

  final payload = jsonEncode({
    'type': type,
    if (targetId != null && targetId.isNotEmpty) 'targetId': targetId,
  });

  final androidDetails = AndroidNotificationDetails(
    highImportanceChannelId,
    highImportanceChannelName,
    channelDescription: 'Urgent campus alerts: posts, announcements, feedback',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    category: AndroidNotificationCategory.message,
    visibility: NotificationVisibility.public,
    ticker: title,
    // Heads-up / banner when the phone is unlocked.
    fullScreenIntent: false,
    styleInformation: BigTextStyleInformation(
      body.isEmpty ? title : body,
      contentTitle: title,
      summaryText: 'UDSM Connect',
    ),
  );

  // Unique id so concurrent alerts don't replace each other incorrectly.
  final id = message.messageId?.hashCode ??
      DateTime.now().millisecondsSinceEpoch.remainder(100000);

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    NotificationDetails(android: androidDetails),
    payload: payload,
  );

  if (kDebugMode) {
    debugPrint('Local heads-up shown: id=$id title=$title');
  }
}

/// Registers the FCM token with the backend.
/// IMPORTANT: Only call this when the user is authenticated, otherwise
/// the backend will reject the request with 401.
Future<void> registerFcmTokenIfPossible() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedAuthToken = prefs.getString('auth_token');
    if (storedAuthToken == null || storedAuthToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('FCM token registration skipped — user not authenticated');
      }
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'FCM token registration skipped — no FCM token (permission?)',
        );
      }
      return;
    }
    await NotificationRepository().registerToken(token);
    if (kDebugMode) {
      debugPrint('FCM token registered with backend: ${token.substring(0, 20)}...');
    }
  } catch (e) {
    if (kDebugMode) debugPrint('FCM token register failed: $e');
  }
}

/// Unregister this device from push before clearing the auth session.
/// Call while the JWT is still present so the API accepts the request.
Future<void> unregisterFcmTokenIfPossible() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final storedAuthToken = prefs.getString('auth_token');
    if (storedAuthToken == null || storedAuthToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('FCM token unregister skipped — user not authenticated');
      }
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    try {
      await NotificationRepository().unregisterToken(fcmToken: token);
      if (kDebugMode) debugPrint('FCM token unregistered with backend');
    } catch (e) {
      if (kDebugMode) debugPrint('FCM token unregister API failed: $e');
    }

    await FirebaseMessaging.instance.deleteToken();
  } catch (e) {
    if (kDebugMode) debugPrint('FCM token unregister failed: $e');
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
