import 'package:flutter/material.dart';
import '../../../core/services/launcher_service.dart';
import '../../../state/app_store.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.call_outlined),
              title: const Text('Appeler le support'),
              subtitle: const Text('+213 555 00 00 00'),
              onTap: () => LauncherService().callPhone('+213555000000'),
            ),
          ),
          const Card(
            child: ListTile(
              leading: Icon(Icons.chat_bubble_outline),
              title: Text('WhatsApp assistance'),
              subtitle: Text('Support rapide'),
            ),
          ),
        ],
      ),
    );
  }
}
