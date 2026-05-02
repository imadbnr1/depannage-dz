import 'package:depaniny/models/service_type.dart';
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
                  const SizedBox(height: 12),
                  _InfoRow(label: 'Service', value: request.service.label),
                  _InfoRow(label: 'Vehicule', value: '${request.vehicleType} · ${request.brandModel}'),
                  _InfoRow(label: 'Pick up', value: request.pickupLabel),
                  if (request.destination.isNotEmpty)
                    _InfoRow(label: 'Destination', value: request.destination),
                  _InfoRow(label: 'Paiement', value: request.payment),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
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
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}