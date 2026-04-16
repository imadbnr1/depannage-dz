import 'package:flutter/material.dart';
import '../../../state/app_store.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adresses enregistrees')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: store.savedAddresses.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(store.savedAddresses[index]),
            ),
          );
        },
      ),
    );
  }
}
