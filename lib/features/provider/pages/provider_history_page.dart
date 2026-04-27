import 'package:flutter/material.dart';

import '../../../models/service_type.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/app_empty_state.dart';
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
    final providerId = store.currentProviderUid;
    if (providerId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final history = store.requests
        .where((r) => r.providerUid == providerId)
        .where((r) =>
            r.status == RequestStatus.completed ||
            r.status == RequestStatus.cancelled)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _ProviderHistoryHero(),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const AppEmptyState(
                icon: Icons.history_outlined,
                title: 'Aucune mission terminee',
                message:
                    'Vos missions completees ou annulees apparaitront ici avec leur resume.',
              )
            else
              ...history.map(
                (item) => PanelCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.customerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (item.estimatedPrice != null)
                            Text(
                              '${item.estimatedPrice!.toStringAsFixed(0)} DA',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                        ],
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
                        title: 'Service',
                        value: item.service.label,
                      ),
                      InfoRow(
                        title: 'Vehicule',
                        value: '${item.vehicleType} · ${item.brandModel}',
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
                          label: const Text('Voir le recu'),
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

class _ProviderHistoryHero extends StatelessWidget {
  const _ProviderHistoryHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFCF8),
            Color(0xFFF7F0E5),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE8E1D5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProviderHistoryHeroIcon(),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historique provider',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Consultez vos missions passees, leurs montants et le recu detaille.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderHistoryHeroIcon extends StatelessWidget {
  const _ProviderHistoryHeroIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.receipt_long_outlined,
        color: Color(0xFF7C3AED),
      ),
    );
  }
}
