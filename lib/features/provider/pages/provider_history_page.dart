import 'package:flutter/material.dart';

import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';
import '../../shared/pages/mission_receipt_page.dart';

class ProviderHistoryPage extends StatelessWidget {
  const ProviderHistoryPage({
    super.key,
    required this.store,
  });

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final providerId = store.selectedProvider.id;
    final history = store.requests
        .where((r) => r.providerUid == providerId)
        .where((r) =>
            r.status == RequestStatus.completed ||
            r.status == RequestStatus.cancelled)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique provider'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (history.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('Aucune mission terminee'),
                ),
              ),
            ...history.map(
              (item) => PanelCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.status.label,
                      style: TextStyle(
                        color: item.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InfoRow(
                      title: 'Vehicule',
                      value: '${item.vehicleType} · ${item.brandModel}',
                    ),
                    if (item.estimatedPrice != null)
                      InfoRow(
                        title: 'Prix',
                        value: '${item.estimatedPrice!.toStringAsFixed(0)} DA',
                      ),
                    if (item.destination.isNotEmpty)
                      InfoRow(
                        title: 'Destination',
                        value: item.destination,
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MissionReceiptPage(
                                store: store,
                                requestId: item.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('Voir recu'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}