import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/routing_service.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../shared/pages/chat_page.dart';

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
  double? _routeProgress;
  LatLng? _lastRouteStart;
  bool _didAutoFitRoute = false;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_handleStoreChanged);

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
    widget.store.removeListener(_handleStoreChanged);
    _trackingSub?.cancel();
    _routeTimer?.cancel();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _scheduleRouteUpdate() {
    _routeTimer?.cancel();
    _routeTimer = Timer(const Duration(seconds: 3), _loadRoute);
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

      if (movedMeters < 12) {
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
          _routeProgress = null;
        });
      } else {
        final estimatedTotalMeters =
            (request.estimatedDistanceKm ?? (route.distanceMeters / 1000)) *
                1000;
        final progress = estimatedTotalMeters <= 0
            ? null
            : ((estimatedTotalMeters - route.distanceMeters) /
                    estimatedTotalMeters)
                .clamp(0.0, 1.0);

        setState(() {
          _routePoints = route.points;
          _routeDistanceMeters = route.distanceMeters;
          _routeDurationSeconds = route.durationSeconds;
          _routeProgress = progress;
        });
      }

      _fitRoute(providerPosition, customerPosition);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _routePoints = [providerPosition, customerPosition];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
        _routeProgress = null;
      });

      _fitRoute(providerPosition, customerPosition);
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  void _fitRoute(LatLng a, LatLng b) {
    if (_didAutoFitRoute) return;
    final bounds = LatLngBounds.fromPoints([a, b]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(48),
      ),
    );
    _didAutoFitRoute = true;
  }

  void _recenterRoute(LatLng a, LatLng b) {
    _didAutoFitRoute = false;
    _fitRoute(a, b);
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
      case RequestStatus.accepted:
        return 'Passer en route';
      case RequestStatus.onTheWay:
        return 'Confirmer arrivee';
      case RequestStatus.arrived:
        return 'Commencer service';
      case RequestStatus.inService:
        return 'Terminer mission';
      default:
        return 'Suivi en cours';
    }
  }

  bool _canAdvance(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.onTheWay ||
        status == RequestStatus.arrived ||
        status == RequestStatus.inService;
  }

  Future<void> _callClient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
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
          icon: Icons.person_pin_circle_rounded,
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
            label: 'DEPANNAGE',
            icon: Icons.car_repair_rounded,
            color: Color(0xFFF59E0B),
          ),
        ),
      );
    }

    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
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
          Positioned(
            top: topInset + 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _MapGlassButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TopTrackingBanner(
                    title: request.customerName,
                    status: _statusLabel(request.status),
                    color: _statusColor(request.status),
                  ),
                ),
                const SizedBox(width: 10),
                _MapGlassButton(
                  icon: Icons.my_location_outlined,
                  onTap: providerPosition == null
                      ? null
                      : () =>
                          _recenterRoute(providerPosition, customerPosition),
                ),
              ],
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _TrackingOverlayCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _InfoBox(
                          title: 'Distance',
                          value: _formatDistance(),
                          accent: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          title: 'ETA',
                          value: _formatEta(),
                          accent: const Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _InfoBox(
                          title: 'Action',
                          value: _canAdvance(request.status)
                              ? 'Disponible'
                              : 'Bloquee',
                          accent: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  if (_routeProgress != null) ...[
                    const SizedBox(height: 8),
                    _CompactProgressCard(progress: _routeProgress!),
                  ],
                  const SizedBox(height: 8),
                  _SummaryInlineRow(
                    icon: Icons.place_rounded,
                    title: 'Depart',
                    value: request.pickupLabel,
                  ),
                  const SizedBox(height: 6),
                  _SummaryInlineRow(
                    icon: Icons.outlined_flag_rounded,
                    title: 'Destination',
                    value: request.destination,
                  ),
                  const SizedBox(height: 6),
                  _SummaryInlineRow(
                    icon: Icons.phone_outlined,
                    title: 'Client',
                    value: request.customerPhone,
                  ),
                  if (_loadingRoute)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Calcul de l itineraire...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _BottomActionIconButton(
                        icon: Icons.phone_outlined,
                        onPressed: request.customerPhone.trim().isEmpty
                            ? null
                            : () => _callClient(request.customerPhone),
                      ),
                      const SizedBox(width: 8),
                      _BottomActionIconButton(
                        icon: Icons.chat_bubble_outline,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                requestId: request.id,
                                title: 'Chat client',
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _canAdvance(request.status)
                              ? () =>
                                  widget.store.advanceMission(widget.requestId)
                              : null,
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(_actionLabel(request.status)),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.88),
                color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _CompactProgressCard extends StatelessWidget {
  const _CompactProgressCard({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression ${(100 * progress).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingOverlayCard extends StatelessWidget {
  const _TrackingOverlayCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MapGlassButton extends StatelessWidget {
  const _MapGlassButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          child: Icon(icon, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

class _TopTrackingBanner extends StatelessWidget {
  const _TopTrackingBanner({
    required this.title,
    required this.status,
    required this.color,
  });

  final String title;
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryInlineRow extends StatelessWidget {
  const _SummaryInlineRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4D6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFF59E0B), size: 16),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 78,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomActionIconButton extends StatelessWidget {
  const _BottomActionIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
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
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
