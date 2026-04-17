import 'package:flutter/foundation.dart';

class InAppNotificationItem {
  const InAppNotificationItem({
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
  });

  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
}

class InAppNotificationService {
  static final ValueNotifier<InAppNotificationItem?> notifier =
      ValueNotifier<InAppNotificationItem?>(null);

  Future<void> push({
    required String title,
    required String body,
    required String type,
  }) async {
    notifier.value = InAppNotificationItem(
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
    );
  }
}