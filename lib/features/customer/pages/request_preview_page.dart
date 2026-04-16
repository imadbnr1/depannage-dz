import 'package:depannage_dz_pro_structured/models/request_status.dart';
import 'package:flutter/material.dart';

import '../../../state/app_store.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';
import 'customer_shell_page.dart';

class RequestPreviewPage extends StatelessWidget {
  const RequestPreviewPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  String _serviceLabel(dynamic service) {
    try {
      final dynamic label = service.label;
      if (label is String && label.trim().isNotEmpty) {
        return label;
      }
    } catch (_) {}

    final raw = service.toString();
    if (raw.contains('.')) {
      return raw.split('.').last;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final request = store.findRequest(requestId);

    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('Demande introuvable')),
      );
    }

    final hasEstimate = request.hasEstimatedTrip;
    final isTowing =
        _serviceLabel(request.service).toLowerCase().contains('remorquage');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isTowing
                      ? const [
                          Color(0xFFDC2626),
                          Color(0xFFF97316),
                        ]
                      : const [
                          Color(0xFF16A34A),
                          Color(0xFF22C55E),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                'Demande envoyee avec succes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (hasEstimate)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniInfoBox(
                        title: 'Distance',
                        value:
                            '${(request.estimatedDistanceKm ?? 0).toStringAsFixed(1)} km',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        title: 'Delai',
                        value: '${request.estimatedDurationMinutes ?? 0} min',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MiniInfoBox(
                        title: 'Prix',
                        value:
                            '${(request.estimatedPrice ?? 0).toStringAsFixed(0)} DA',
                      ),
                    ),
                  ],
                ),
              ),
            if (hasEstimate) const SizedBox(height: 12),
            PanelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resume mission',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InfoRow(title: 'Service', value: _serviceLabel(request.service)),
                  InfoRow(
                    title: 'Vehicule',
                    value: '${request.vehicleType} · ${request.brandModel}',
                  ),
                  InfoRow(title: 'Paiement', value: request.payment),
                  InfoRow(title: 'Etat', value: request.status.label),
                  InfoRow(title: 'Repere', value: request.landmark),
                  InfoRow(title: 'Description', value: request.issueDescription),
                  if (request.destination.isNotEmpty)
                    InfoRow(title: 'Destination', value: request.destination),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                store.setCustomerTab(1);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => CustomerShellPage(store: store),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Voir mes demandes'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                store.setCustomerTab(0);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => CustomerShellPage(store: store),
                  ),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Retour accueil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  const _MiniInfoBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}