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

    if (!kIsWeb) {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(
        android: androidInit,
      );
      await flutterLocalNotificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          final raw = details.payload;
          if (raw == null || raw.isEmpty) return;
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map) {
              payloadNotifier.value = decoded.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              );
            }
          } catch (_) {}
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

    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        payloadNotifier.value = initialMessage.data.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('FCM initial message unavailable.');
      }
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
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
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

    if (!kIsWeb) {
      try {
        final token = await messaging.getToken();
        if (kDebugMode && token != null) {
          debugPrint('FCM token saved');
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint('FCM token unavailable.');
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) {
          if (kDebugMode) {
            debugPrint('FCM token refreshed');
          }
        },
        onError: (_) {
          if (kDebugMode) {
            debugPrint('FCM token refresh unavailable.');
          }
        },
      );
    }
  }

  static void clearPayload() {
    payloadNotifier.value = null;
  }
}
