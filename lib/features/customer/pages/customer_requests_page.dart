import 'package:flutter/material.dart';

import '../../../models/app_request.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/panel_card.dart';
import '../../shared/pages/mission_receipt_page.dart';
import 'customer_rate_provider_page.dart';
import 'customer_tracking_page.dart';

class CustomerRequestsPage extends StatelessWidget {
  const CustomerRequestsPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final active = store.activeCustomerRequests;
    final history = store.historyCustomerRequests;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Demandes actives',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const SizedBox(
                height: 220,
                child: AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aucune demande active',
                  message:
                      'Vos demandes en cours apparaitront ici des leur creation.',
                ),
              ),
            ...active.map(
              (request) => _CustomerRequestCard(
                store: store,
                request: request,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Historique',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            if (history.isEmpty)
              const SizedBox(
                height: 220,
                child: AppEmptyState(
                  icon: Icons.history_outlined,
                  title: 'Aucun historique',
                  message:
                      'Les missions completees et annulees seront affichees ici.',
                ),
              ),
            ...history.map(
              (request) => _CustomerHistoryCard(
                store: store,
                request: request,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerRequestCard extends StatelessWidget {
  const _CustomerRequestCard({
    required this.store,
    required this.request,
  });

  final AppStore store;
  final AppRequest request;

  bool get _canTrack {
    return request.status == RequestStatus.accepted ||
        request.status == RequestStatus.onTheWay ||
        request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed;
  }

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ServiceBadge(service: request.service),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceLabel(request),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.status.label,
                      style: TextStyle(
                        color: request.status.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                request.estimatedPrice != null
                    ? '${request.estimatedPrice!.toStringAsFixed(0)} DA'
                    : '--',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniBadge(label: request.urgency),
              _MiniBadge(label: request.payment),
              if (request.estimatedDistanceKm != null)
                _MiniBadge(
                  label: '${request.estimatedDistanceKm!.toStringAsFixed(1)} km',
                ),
              if (request.estimatedDurationMinutes != null)
                _MiniBadge(
                  label: '${request.estimatedDurationMinutes} min',
                ),
            ],
          ),
          const SizedBox(height: 10),
          InfoRow(
            title: 'Vehicule',
            value: '${request.vehicleType} · ${request.brandModel}',
          ),
          InfoRow(
            title: 'Position',
            value: '${request.pickupLabel}\n${request.pickupSubtitle}',
          ),
          InfoRow(
            title: 'Repere',
            value: request.landmark,
          ),
          InfoRow(
            title: 'Description',
            value: request.issueDescription,
          ),
          if (request.destination.isNotEmpty)
            InfoRow(
              title: 'Destination',
              value: request.destination,
            ),
          if ((request.providerName ?? '').isNotEmpty)
            InfoRow(
              title: 'Provider',
              value: request.providerName!,
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canTrack
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CustomerTrackingPage(
                                store: store,
                                requestId: request.id,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Tracking'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: request.status == RequestStatus.searching
                      ? () async {
                          await store.cancelRequest(request.id);
                        }
                      : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _serviceLabel(AppRequest request) {
    final dynamic anyService = request.service;

    try {
      final dynamic label = anyService.label;
      if (label is String && label.trim().isNotEmpty) {
        return label;
      }
    } catch (_) {}

    final raw = request.service.toString();
    if (raw.contains('.')) {
      return raw.split('.').last;
    }
    return raw;
  }
}

class _CustomerHistoryCard extends StatelessWidget {
  const _CustomerHistoryCard({
    required this.store,
    required this.request,
  });

  final AppStore store;
  final AppRequest request;

  @override
  Widget build(BuildContext context) {
    final canRate = request.canClientRate;

    return PanelCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _serviceLabel(request),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            request.status.label,
            style: TextStyle(
              color: request.status.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (request.estimatedPrice != null)
            InfoRow(
              title: 'Prix estime',
              value: '${request.estimatedPrice!.toStringAsFixed(0)} DA',
            ),
          if (request.estimatedDistanceKm != null)
            InfoRow(
              title: 'Distance',
              value: '${request.estimatedDistanceKm!.toStringAsFixed(1)} km',
            ),
          if (request.estimatedDurationMinutes != null)
            InfoRow(
              title: 'Duree',
              value: '${request.estimatedDurationMinutes} min',
            ),
          InfoRow(
            title: 'Vehicule',
            value: '${request.vehicleType} · ${request.brandModel}',
          ),
          if (request.destination.isNotEmpty)
            InfoRow(
              title: 'Destination',
              value: request.destination,
            ),
          if ((request.providerName ?? '').isNotEmpty)
            InfoRow(
              title: 'Provider',
              value: request.providerName!,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MissionReceiptPage(
                          store: store,
                          requestId: request.id,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Recu'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canRate
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CustomerRateProviderPage(
                                store: store,
                                requestId: request.id,
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Evaluer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _serviceLabel(AppRequest request) {
    final dynamic anyService = request.service;

    try {
      final dynamic label = anyService.label;
      if (label is String && label.trim().isNotEmpty) {
        return label;
      }
    } catch (_) {}

    final raw = request.service.toString();
    if (raw.contains('.')) {
      return raw.split('.').last;
    }
    return raw;
  }
}

class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({
    required this.service,
  });

  final dynamic service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _serviceIcon(service),
        color: const Color(0xFF0F172A),
      ),
    );
  }

  IconData _serviceIcon(dynamic service) {
    try {
      final dynamic icon = service.icon;
      if (icon is IconData) return icon;
    } catch (_) {}

    final raw = service.toString().toLowerCase();
    if (raw.contains('remorquage')) return Icons.local_shipping_outlined;
    if (raw.contains('batterie')) return Icons.battery_charging_full;
    if (raw.contains('pneu')) return Icons.tire_repair;
    return Icons.build_circle_outlined;
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}