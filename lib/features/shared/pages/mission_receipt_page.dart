import 'package:depannage_dz_pro_structured/models/service_type.dart';
import 'package:flutter/material.dart';

import '../../../models/request_status.dart';
import '../../../state/app_store.dart';

class MissionReceiptPage extends StatelessWidget {
  const MissionReceiptPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final request = store.findRequest(requestId);

    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('Mission introuvable')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: request.status == RequestStatus.completed
                      ? const [
                          Color(0xFF16A34A),
                          Color(0xFF22C55E),
                        ]
                      : const [
                          Color(0xFFDC2626),
                          Color(0xFFF97316),
                        ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Icon(
                    request.status == RequestStatus.completed
                        ? Icons.check_circle
                        : Icons.info_outline,
                    color: Colors.white,
                    size: 46,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    request.status == RequestStatus.completed
                        ? 'Mission terminee'
                        : request.status.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.completedAt != null
                        ? request.completedAt!
                            .toLocal()
                            .toString()
                            .substring(0, 16)
                        : request.createdAt.toLocal().toString().substring(0, 16),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant estime',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '${(request.estimatedPrice ?? 0).toStringAsFixed(0)} DA',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      request.payment,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details mission',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  _Row('Service', request.service.label),
                  _Row(
                    'Vehicule',
                    '${request.vehicleType} · ${request.brandModel}',
                  ),
                  _Row('Paiement', request.payment),
                  _Row('Urgence', request.urgency),
                  if (request.estimatedDistanceKm != null)
                    _Row(
                      'Distance',
                      '${request.estimatedDistanceKm!.toStringAsFixed(1)} km',
                    ),
                  if (request.estimatedDurationMinutes != null)
                    _Row(
                      'Duree',
                      '${request.estimatedDurationMinutes} min',
                    ),
                  _Row('Repere', request.landmark),
                  if (request.destination.isNotEmpty)
                    _Row('Destination', request.destination),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Client',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  _Row('Nom', request.customerName),
                  _Row('Telephone', request.customerPhone),
                  _Row('Position', request.pickupLabel),
                ],
              ),
            ),
            if ((request.providerName ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Provider',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    _Row('Nom', request.providerName!),
                    _Row('Telephone', request.providerPhone ?? '--'),
                    _Row(
                      'Vehicule',
                      '${request.providerVehicle ?? '--'} · ${request.providerPlate ?? '--'}',
                    ),
                  ],
                ),
              ),
            ],
            if (request.clientRatingForProvider != null) ...[
              const SizedBox(height: 14),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre evaluation',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⭐ ${request.clientRatingForProvider!.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if ((request.clientReviewForProvider ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          request.clientReviewForProvider!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (request.providerRatingForClient != null) ...[
              const SizedBox(height: 14),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evaluation provider',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '⭐ ${request.providerRatingForClient!.toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    if ((request.providerReviewForClient ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          request.providerReviewForClient!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.title, this.value);

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}