class InAppNotificationItem {
  const InAppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;
}