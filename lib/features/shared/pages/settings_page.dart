import 'package:flutter/material.dart';
import '../../../state/app_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: const Center(
        child: Text('Profil'),
      ),
    );
  }
}
