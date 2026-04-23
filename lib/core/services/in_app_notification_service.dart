import 'package:flutter/foundation.dart';

class InAppNotificationItem {
  const InAppNotificationItem({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.imageUrl,
    this.popupMode,
    this.playSound = false,
  });

  final String? id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final String? imageUrl;
  final String? popupMode;
  final bool playSound;
}

class InAppNotificationService {
  static final ValueNotifier<InAppNotificationItem?> notifier =
      ValueNotifier<InAppNotificationItem?>(null);

  Future<void> push({
    String? id,
    required String title,
    required String body,
    required String type,
    String? imageUrl,
    String? popupMode,
    bool playSound = false,
  }) async {
    notifier.value = InAppNotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      imageUrl: imageUrl,
      popupMode: popupMode,
      playSound: playSound,
    );
  }
}
