import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/routing_service.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';

class ProviderTrackingPage extends StatefulWidget {
  const ProviderTrackingPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  @override
  State<ProviderTrackingPage> createState() => _ProviderTrackingPageState();
}

class _ProviderTrackingPageState extends State<ProviderTrackingPage> {
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  StreamSubscription? _trackingSub;
  Timer? _routeTimer;

  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  LatLng? _lastRouteStart;

  @override
  void initState() {
    super.initState();

    _trackingSub = widget.store.watchTracking(widget.requestId).listen((_) {
      if (!mounted) return;
      _scheduleRouteUpdate();
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleRouteUpdate();
    });
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    _routeTimer?.cancel();
    super.dispose();
  }

  void _scheduleRouteUpdate() {
    _routeTimer?.cancel();
    _routeTimer = Timer(const Duration(seconds: 4), _loadRoute);
  }

  Future<void> _loadRoute() async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    final tracking = widget.store.trackingFor(widget.requestId);
    final providerPosition = tracking?.providerPosition ??
        widget.store.providerCurrentPosition ??
        request.providerPosition;
    final customerPosition =
        tracking?.customerPosition ?? request.customerPosition;

    if (providerPosition == null) return;

    if (_lastRouteStart != null) {
      final movedMeters = const Distance().as(
        LengthUnit.Meter,
        _lastRouteStart!,
        providerPosition,
      );

      if (movedMeters < 20) {
        return;
      }
    }

    _lastRouteStart = providerPosition;

    if (!mounted) return;
    setState(() => _loadingRoute = true);

    try {
      final route = await _routingService.getRoute(
        providerPosition,
        customerPosition,
      );

      if (!mounted) return;

      if (route == null || route.points.isEmpty) {
        setState(() {
          _routePoints = [providerPosition, customerPosition];
          _routeDistanceMeters = null;
          _routeDurationSeconds = null;
        });
      } else {
        setState(() {
          _routePoints = route.points;
          _routeDistanceMeters = route.distanceMeters;
          _routeDurationSeconds = route.durationSeconds;
        });
      }

      _fitRoute(providerPosition, customerPosition);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _routePoints = [providerPosition, customerPosition];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
      });

      _fitRoute(providerPosition, customerPosition);
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  void _fitRoute(LatLng a, LatLng b) {
    final bounds = LatLngBounds.fromPoints([a, b]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
  }

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.searching:
        return 'Recherche provider';
      case RequestStatus.accepted:
        return 'Mission acceptee';
      case RequestStatus.onTheWay:
        return 'En route';
      case RequestStatus.arrived:
        return 'Arrive';
      case RequestStatus.inService:
        return 'Service en cours';
      case RequestStatus.completed:
        return 'Mission terminee';
      case RequestStatus.cancelled:
        return 'Mission annulee';
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.searching:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.onTheWay:
        return Colors.orange;
      case RequestStatus.arrived:
        return Colors.green;
      case RequestStatus.inService:
        return Colors.teal;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDistance() {
    final meters = _routeDistanceMeters;
    if (meters == null) return '--';
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatEta() {
    final seconds = _routeDurationSeconds;
    if (seconds == null) return '--';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  String _actionLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.arrived:
        return 'Commencer service';
      case RequestStatus.inService:
        return 'Terminer mission';
      default:
        return 'Suivi en cours';
    }
  }

  bool _canAdvance(RequestStatus status) {
    return status == RequestStatus.arrived ||
        status == RequestStatus.inService;
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  Future<void> _startNavigation(LatLng destination) async {
    final googleUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving&dir_action=navigate',
    );

    final wazeUri = Uri.parse(
      'https://waze.com/ul?ll=${destination.latitude},${destination.longitude}&navigate=yes',
    );

    if (await canLaunchUrl(wazeUri)) {
      await launchUrl(wazeUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(googleUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) {
      return const Scaffold(
        body: Center(
          child: Text('Mission introuvable'),
        ),
      );
    }

    final tracking = widget.store.trackingFor(widget.requestId);
    final customerPosition =
        tracking?.customerPosition ?? request.customerPosition;
    final providerPosition = tracking?.providerPosition ??
        widget.store.providerCurrentPosition ??
        request.providerPosition;

    final markers = <Marker>[
      Marker(
        point: customerPosition,
        width: 110,
        height: 80,
        child: const _PinnedMarker(
          label: 'Client',
          icon: Icons.place,
          color: Colors.red,
        ),
      ),
    ];

    if (providerPosition != null) {
      markers.add(
        Marker(
          point: providerPosition,
          width: 120,
          height: 80,
          child: const _PinnedMarker(
            label: 'Provider',
            icon: Icons.local_shipping,
            color: Colors.blue,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking mission'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: customerPosition,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dz.depannage.provider',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 5,
                        color: Colors.green,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.customerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusLabel(request.status),
                    style: TextStyle(
                      color: _statusColor(request.status),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          title: 'Distance',
                          value: _formatDistance(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoBox(
                          title: 'ETA',
                          value: _formatEta(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    request.landmark,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Destination: ${request.destination}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  if (_loadingRoute) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Calcul de l itineraire...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: request.customerPhone.trim().isEmpty
                              ? null
                              : () => _callClient(request.customerPhone),
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('Appeler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Le chat est gere dans la page chat.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Chat'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startNavigation(customerPosition),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Maps'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _canAdvance(request.status)
                          ? () => widget.store.advanceMission(widget.requestId)
                          : null,
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(_actionLabel(request.status)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedMarker extends StatelessWidget {
  const _PinnedMarker({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          icon,
          color: color,
          size: 34,
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
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
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}