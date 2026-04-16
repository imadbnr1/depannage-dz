import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for new orders and mission updates.',
  importance: Importance.max,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FcmService {
  static final ValueNotifier<Map<String, String>?> payloadNotifier =
      ValueNotifier<Map<String, String>?>(null);

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();

    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          final raw = details.payload;
          if (raw == null || raw.isEmpty) return;
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            payloadNotifier.value = decoded.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            );
          }
        },
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highImportanceChannel);

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      payloadNotifier.value = initialMessage.data.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      payloadNotifier.value = data.isEmpty ? null : data;

      final notification = message.notification;
      final android = notification?.android;

      if (!kIsWeb && notification != null && android != null) {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              highImportanceChannel.id,
              highImportanceChannel.name,
              channelDescription: highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      } else {
        debugPrint(
          'FCM foreground: ${notification?.title} - ${notification?.body}',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      payloadNotifier.value = message.data.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    });

    try {
      final token = await messaging.getToken();
      debugPrint('FCM TOKEN: $token');
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  static void clearPayload() {
    payloadNotifier.value = null;
  }
}