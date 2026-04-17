import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/routing_service.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';

class CustomerTrackingPage extends StatefulWidget {
  const CustomerTrackingPage({
    super.key,
    required this.store,
    required this.requestId,
  });

  final AppStore store;
  final String requestId;

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  final MapController _mapController = MapController();
  final RoutingService _routingService = RoutingService();

  StreamSubscription? _trackingSub;
  Timer? _routeTimer;

  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;

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
    _routeTimer = Timer(const Duration(seconds: 2), _loadRoute);
  }

  Future<void> _loadRoute() async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    final tracking = widget.store.trackingFor(widget.requestId);
    final providerPosition = tracking?.providerPosition ?? request.providerPosition;
    final customerPosition = tracking?.customerPosition ?? request.customerPosition;

    if (providerPosition == null) return;

    setState(() => _loadingRoute = true);

    try {
      final route = await _routingService.getRoute(
        providerPosition,
        customerPosition,
      );

      if (!mounted) return;

      setState(() {
        _routePoints = route.isEmpty
            ? [providerPosition, customerPosition]
            : route;
      });

      _fitRoute(providerPosition, customerPosition);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = [providerPosition, customerPosition];
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
        return 'Provider arrive';
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

  Future<void> _callProvider(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  Future<void> _openMaps(LatLng point) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) {
      return const Scaffold(
        body: Center(child: Text('Mission introuvable')),
      );
    }

    final tracking = widget.store.trackingFor(widget.requestId);
    final customerPosition = tracking?.customerPosition ?? request.customerPosition;
    final providerPosition = tracking?.providerPosition ?? request.providerPosition;

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
                  userAgentPackageName: 'dz.depannage.customer',
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.providerName ?? request.customerName,
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
                  const SizedBox(height: 16),
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
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (request.providerPhone ?? '').trim().isEmpty
                              ? null
                              : () => _callProvider(request.providerPhone!),
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
                                content: Text('Le chat est gere dans la page chat.'),
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
                          onPressed: () => _openMaps(customerPosition),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Maps'),
                        ),
                      ),
                    ],
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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