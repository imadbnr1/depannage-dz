import 'package:flutter/material.dart';
import '../../../state/app_store.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: store.notifications.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_none),
              title: Text(store.notifications[index]),
            ),
          );
        },
      ),
    );
  }
}
