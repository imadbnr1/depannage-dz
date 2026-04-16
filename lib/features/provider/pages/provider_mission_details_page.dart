import 'package:depannage_dz_pro_structured/models/service_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/launcher_service.dart';
import '../../../core/services/route_service.dart';
import '../../../models/request_status.dart';
import '../../../models/route_snapshot.dart';
import '../../../state/app_store.dart';
import '../../../widgets/info_row.dart';
import '../../../widgets/map_pin.dart';
import 'provider_tracking_page.dart';

class ProviderMissionDetailsPage extends StatefulWidget {
  const ProviderMissionDetailsPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  @override
  State<ProviderMissionDetailsPage> createState() =>
      _ProviderMissionDetailsPageState();
}

class _ProviderMissionDetailsPageState extends State<ProviderMissionDetailsPage> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  bool _isValidPoint(LatLng p) {
    return p.latitude.isFinite &&
        p.longitude.isFinite &&
        !p.latitude.isNaN &&
        !p.longitude.isNaN;
  }

  List<LatLng> _sanitizePoints(List<LatLng> points) {
    final cleaned = points.where(_isValidPoint).toList();
    if (cleaned.isEmpty) return [];
    if (cleaned.length == 1) {
      return [
        cleaned.first,
        LatLng(
          cleaned.first.latitude + 0.0002,
          cleaned.first.longitude + 0.0002,
        ),
      ];
    }
    return cleaned;
  }

  List<LatLng> _safeRoutePoints({
    required LatLng providerPosition,
    required LatLng customerPosition,
    required List<LatLng> routePoints,
  }) {
    final safeProvider =
        _isValidPoint(providerPosition) ? providerPosition : customerPosition;
    final safeCustomer =
        _isValidPoint(customerPosition) ? customerPosition : providerPosition;

    final cleaned = _sanitizePoints(routePoints);
    if (cleaned.length >= 2) return cleaned;

    return [safeProvider, safeCustomer];
  }

  void _fitRoute(List<LatLng> rawPoints) {
    if (!_mapReady) return;

    final points = _sanitizePoints(rawPoints);
    if (points.length < 2) return;

    final first = points.first;
    final last = points.last;
    final samePoint = first.latitude == last.latitude &&
        first.longitude == last.longitude;

    try {
      if (samePoint) {
        _mapController.move(first, 16);
      } else {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 220),
          ),
        );
      }
    } catch (_) {}
  }

  void _recenterRoute(List<LatLng> rawPoints) {
    if (!_mapReady) return;

    final points = _sanitizePoints(rawPoints);
    if (points.length < 2) return;

    final first = points.first;
    final last = points.last;
    final samePoint = first.latitude == last.latitude &&
        first.longitude == last.longitude;

    try {
      if (samePoint) {
        _mapController.move(first, 16);
      } else {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.fromLTRB(40, 80, 40, 220),
          ),
        );
      }
    } catch (_) {}
  }

  String _actionLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.searching:
        return 'Accepter la mission';
      case RequestStatus.accepted:
        return 'Passer en route';
      case RequestStatus.onTheWay:
        return 'Confirmer arrivee';
      case RequestStatus.arrived:
        return 'Commencer service';
      case RequestStatus.inService:
        return 'Terminer mission';
      case RequestStatus.completed:
        return 'Mission terminee';
      case RequestStatus.cancelled:
        return 'Mission annulee';
    }
  }

  Future<void> _handlePrimaryAction(BuildContext context) async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    if (request.status == RequestStatus.searching) {
      await widget.store.acceptRequest(request.id);
      return;
    }

    if (request.status == RequestStatus.accepted ||
        request.status == RequestStatus.onTheWay ||
        request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService) {
      await widget.store.advanceMission(request.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);
    final provider = widget.store.selectedProvider;

    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('Mission introuvable')),
      );
    }

    final providerPosition =
        request.providerPosition ?? widget.store.providerCurrentPosition ?? provider.position;
    final customerPosition = request.customerPosition;

    return FutureBuilder<RouteSnapshot>(
      future: RouteService().buildDrivingRoute(
        origin: providerPosition,
        destination: customerPosition,
      ),
      builder: (context, routeSnapshot) {
        final fallbackDistance = const Distance().as(
          LengthUnit.Kilometer,
          providerPosition,
          customerPosition,
        );

        final route = routeSnapshot.data ??
            RouteSnapshot(
              points: [providerPosition, customerPosition],
              distanceKm: fallbackDistance.isFinite ? fallbackDistance : 0,
              durationMinutes:
                  ((fallbackDistance / 35) * 60).clamp(1, 999).round(),
              isFallback: true,
            );

        final safeRoutePoints = _safeRoutePoints(
          providerPosition: providerPosition,
          customerPosition: customerPosition,
          routePoints: route.points,
        );

        final initialCenter =
            _isValidPoint(providerPosition) ? providerPosition : customerPosition;

        final canAct = request.status != RequestStatus.completed &&
            request.status != RequestStatus.cancelled;

        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 13,
                  onMapReady: () {
                    _mapReady = true;
                    _fitRoute(safeRoutePoints);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'dz.depannage.provider',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: safeRoutePoints,
                        strokeWidth: 6,
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: providerPosition,
                        width: 74,
                        height: 74,
                        child: const MapPin(
                          label: 'Provider',
                          icon: Icons.local_shipping,
                          color: Colors.blue,
                        ),
                      ),
                      Marker(
                        point: customerPosition,
                        width: 70,
                        height: 70,
                        child: const MapPin(
                          label: 'Client',
                          icon: Icons.place,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _FloatingMapButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _FloatingMapButton(
                        icon: Icons.call,
                        onTap: () =>
                            LauncherService().callPhone(request.customerPhone),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                right: 16,
                top: 92,
                child: _FloatingMapButton(
                  icon: Icons.map_outlined,
                  onTap: () => _recenterRoute(safeRoutePoints),
                ),
              ),

              DraggableScrollableSheet(
                initialChildSize: 0.30,
                minChildSize: 0.22,
                maxChildSize: 0.78,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFDBEAFE),
                              child: Text(
                                request.customerName.trim().isEmpty
                                    ? 'CL'
                                    : request.customerName
                                        .trim()
                                        .split(' ')
                                        .map((e) => e.isNotEmpty ? e[0] : '')
                                        .take(2)
                                        .join(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                request.customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: request.status.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                request.status.label,
                                style: TextStyle(
                                  color: request.status.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniStat(
                              label: request.estimatedDistanceKm != null
                                  ? '${request.estimatedDistanceKm!.toStringAsFixed(1)} km'
                                  : '${route.distanceKm.toStringAsFixed(1)} km',
                            ),
                            _MiniStat(
                              label: request.estimatedDurationMinutes != null
                                  ? '${request.estimatedDurationMinutes} min'
                                  : '${route.durationMinutes} min',
                            ),
                            _MiniStat(label: request.urgency),
                            _MiniStat(
                              label: request.estimatedPrice != null
                                  ? '${request.estimatedPrice!.toStringAsFixed(0)} DA'
                                  : request.service.priceLabel,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Identite provider',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFFDCFCE7),
                                    child: Text(
                                      provider.avatarText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                provider.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (provider.isVerified)
                                              const Icon(
                                                Icons.verified,
                                                color: Color(0xFF2563EB),
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '⭐ ${provider.rating.toStringAsFixed(1)} · ${provider.missionsCompleted} missions',
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              InfoRow(
                                title: 'Vehicule',
                                value: provider.vehicleType,
                              ),
                              InfoRow(
                                title: 'Plaque',
                                value: provider.plate,
                              ),
                              InfoRow(
                                title: 'Telephone',
                                value: provider.phone,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informations client',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 10),
                              InfoRow(
                                title: 'Telephone',
                                value: request.customerPhone,
                              ),
                              InfoRow(
                                title: 'Service',
                                value: request.service.label,
                              ),
                              InfoRow(
                                title: 'Vehicule',
                                value:
                                    '${request.vehicleType} · ${request.brandModel}',
                              ),
                              InfoRow(
                                title: 'Position',
                                value:
                                    '${request.pickupLabel}\n${request.pickupSubtitle}',
                              ),
                              InfoRow(
                                title: 'Repere',
                                value: request.landmark,
                              ),
                              InfoRow(
                                title: 'Description',
                                value: request.issueDescription,
                              ),
                              InfoRow(
                                title: 'Paiement',
                                value: request.payment,
                              ),
                              if (request.destination.isNotEmpty)
                                InfoRow(
                                  title: 'Destination',
                                  value: request.destination,
                                ),
                              if (request.photoHint.isNotEmpty)
                                InfoRow(
                                  title: 'Detail visuel',
                                  value: request.photoHint,
                                ),
                              if (request.completedAt != null)
                                InfoRow(
                                  title: 'Terminee le',
                                  value: request.completedAt!
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16),
                                ),
                            ],
                          ),
                        ),

                        if (request.isClientRated &&
                            request.clientRatingForProvider != null) ...[
                          const SizedBox(height: 14),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Avis du client',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '⭐ ${request.clientRatingForProvider!.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                if ((request.clientReviewForProvider ?? '')
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      request.clientReviewForProvider!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        if (request.isProviderRated &&
                            request.providerRatingForClient != null) ...[
                          const SizedBox(height: 14),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Votre avis sur le client',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '⭐ ${request.providerRatingForClient!.toStringAsFixed(1)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                if ((request.providerReviewForClient ?? '')
                                    .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      request.providerReviewForClient!,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => LauncherService()
                                    .callPhone(request.customerPhone),
                                icon: const Icon(Icons.call_outlined),
                                label: const Text('Appeler'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  LauncherService().openGoogleMaps(
                                    origin: providerPosition,
                                    destination: customerPosition,
                                  );
                                },
                                icon: const Icon(Icons.navigation_outlined),
                                label: const Text('Itineraire'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProviderTrackingPage(
                                    store: widget.store,
                                    requestId: request.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Tracking'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: canAct
                                ? () => _handlePrimaryAction(context)
                                : null,
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(_actionLabel(request.status)),
                          ),
                        ),
                        if (request.status == RequestStatus.searching) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await widget.store
                                    .rejectRequestForCurrentProvider(request.id);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: const Icon(Icons.close),
                              label: const Text('Rejeter'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}