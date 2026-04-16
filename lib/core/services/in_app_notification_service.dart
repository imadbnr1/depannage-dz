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

class InAppNotificationService extends ChangeNotifier {
  final List<InAppNotificationItem> _items = [];

  List<InAppNotificationItem> get items => List.unmodifiable(_items);

  void push({
    required String title,
    required String body,
    required String type,
  }) {
    _items.insert(
      0,
      InAppNotificationItem(
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  InAppNotificationItem? get latest => _items.isEmpty ? null : _items.first;
}