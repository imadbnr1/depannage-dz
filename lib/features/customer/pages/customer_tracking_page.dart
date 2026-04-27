import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/routing_service.dart';
import '../../../models/app_request.dart';
import '../../../models/request_status.dart';
import '../../../state/app_store.dart';
import '../../../widgets/role_map_marker.dart';
import '../../shared/pages/chat_page.dart';

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
  Timer? _offerTimer;
  Timer? _providerAnimationTimer;

  List<LatLng> _routePoints = [];
  bool _loadingRoute = false;
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  double? _routeProgress;
  LatLng? _lastRouteStart;
  LatLng? _lastRouteTarget;
  RequestStatus? _lastRouteStatus;
  bool _didAutoFitRoute = false;
  double? _lastProviderHeadingRadians;
  LatLng? _renderedProviderPosition;
  LatLng? _previousProviderPosition;
  LatLng? _lastTargetPosition;
  bool _followProvider = true;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_handleStoreChanged);

    _trackingSub = widget.store.watchTracking(widget.requestId).listen((_) {
      if (!mounted) return;
      final request = widget.store.findRequest(widget.requestId);
      if (request != null) {
        _syncAnimatedProviderPosition(request);
      }
      _scheduleRouteUpdate();
      setState(() {});
    });

    _offerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final request = widget.store.findRequest(widget.requestId);
      if (request?.status == RequestStatus.searching &&
          request?.offeredProviderUid != null) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = widget.store.findRequest(widget.requestId);
      if (request != null) {
        _syncAnimatedProviderPosition(request, immediate: true);
      }
      _scheduleRouteUpdate();
      _fitWaitingProviders();
    });

    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove && event.source != MapEventSource.mapController) {
        setState(() => _followProvider = false);
      }
    });
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChanged);
    _trackingSub?.cancel();
    _routeTimer?.cancel();
    _offerTimer?.cancel();
    _providerAnimationTimer?.cancel();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    final request = widget.store.findRequest(widget.requestId);
    if (request != null) {
      _syncAnimatedProviderPosition(request);
    }
    _fitWaitingProviders();
    setState(() {});
  }

  void _syncAnimatedProviderPosition(
    AppRequest request, {
    bool immediate = false,
  }) {
    final tracking = widget.store.trackingFor(widget.requestId);
    final targetPosition =
        tracking?.providerPosition ?? request.providerPosition;

    if (targetPosition == null) return;

    // Update previous position for heading calculation
    if (_lastTargetPosition != null && 
        (_lastTargetPosition!.latitude != targetPosition.latitude || 
         _lastTargetPosition!.longitude != targetPosition.longitude)) {
      _previousProviderPosition = _lastTargetPosition;
    }
    _lastTargetPosition = targetPosition;

    final currentPosition = _renderedProviderPosition;
    if (immediate || currentPosition == null) {
      _providerAnimationTimer?.cancel();
      _renderedProviderPosition = targetPosition;
      return;
    }

    final distanceMeters = const Distance().as(
      LengthUnit.Meter,
      currentPosition,
      targetPosition,
    );

    if (distanceMeters < 2) {
      _providerAnimationTimer?.cancel();
      _renderedProviderPosition = targetPosition;
      return;
    }

    final startedAt = DateTime.now();
    
    // ✅ Smooth distance-based duration calculation
    const minDurationMs = 400;
    const maxDurationMs = 1600;
    const idealSpeed = 80; // meters per second
    final calculatedDuration = (distanceMeters / idealSpeed * 1000).round();
    final durationMs = calculatedDuration.clamp(minDurationMs, maxDurationMs);
    final duration = Duration(milliseconds: durationMs);
    
    // ✅ Consistent easeInOut curve for all movements
    const animationCurve = Curves.easeInOutCubic;

    _providerAnimationTimer?.cancel();
    _providerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final elapsed = DateTime.now().difference(startedAt);
        final t = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        final easedT = animationCurve.transform(t);

        final newPosition = _lerpLatLng(
          currentPosition,
          targetPosition,
          easedT,
        );

        setState(() {
          _renderedProviderPosition = newPosition;
        });

        if (_followProvider) {
          _mapController.move(
            newPosition,
            _mapController.camera.zoom,
            id: 'follow',
          );
        }

        if (t >= 1) {
          timer.cancel();
        }
      },
    );
  }

  LatLng _lerpLatLng(LatLng from, LatLng to, double t) {
    return LatLng(
      from.latitude + ((to.latitude - from.latitude) * t),
      from.longitude + ((to.longitude - from.longitude) * t),
    );
  }

  double _upcomingHeadingDeltaRadians({
    required LatLng from,
    required LatLng to,
  }) {
    final currentHeading = _lastProviderHeadingRadians;
    final travelHeading = _bearingRadians(from, to) + (math.pi / 2);
    if (currentHeading == null) return 0;
    return _normalizeAngleRadians(travelHeading - currentHeading).abs();
  }

  void _scheduleRouteUpdate() {
    _routeTimer?.cancel();
    _routeTimer = Timer(const Duration(seconds: 3), _loadRoute);
  }

  void _fitWaitingProviders() {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null || request.status != RequestStatus.searching) return;

    final nearbyProviders = widget.store.nearbyProvidersForCustomer(
      request.customerPosition,
      requestId: request.id,
    );

    if (nearbyProviders.isEmpty) return;

    final points = <LatLng>[
      request.customerPosition,
      ...nearbyProviders.map((provider) => provider.position),
    ];

    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
        ),
      );
    } catch (_) {}
  }

  Future<void> _loadRoute() async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    final tracking = widget.store.trackingFor(widget.requestId);
    final providerPosition =
        tracking?.providerPosition ?? request.providerPosition;
    final customerPosition =
        tracking?.customerPosition ?? request.customerPosition;
    final routeTarget = _routeTarget(request, customerPosition);

    if (providerPosition == null) return;

    final stageChanged = _lastRouteStatus != request.status ||
        _lastRouteTarget == null ||
        const Distance().as(
              LengthUnit.Meter,
              _lastRouteTarget!,
              routeTarget,
            ) >
            12;

    if (stageChanged) {
      _didAutoFitRoute = false;
    }

    if (!stageChanged && _lastRouteStart != null) {
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
    _lastRouteTarget = routeTarget;
    _lastRouteStatus = request.status;

    if (!mounted) return;
    setState(() => _loadingRoute = true);

    try {
      final route = await _routingService.getRoute(
        providerPosition,
        routeTarget,
      );

      if (!mounted) return;

      if (route == null || route.points.isEmpty) {
        setState(() {
          _routePoints = [providerPosition, routeTarget];
          _routeDistanceMeters = null;
          _routeDurationSeconds = null;
          _routeProgress = null;
        });
      } else {
        final estimatedTotalMeters =
            _estimatedTotalMetersForStage(request, route);
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

      _fitRoute(providerPosition, routeTarget);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _routePoints = [providerPosition, routeTarget];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
        _routeProgress = null;
      });

      _fitRoute(providerPosition, routeTarget);
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  LatLng _routeTarget(AppRequest request, LatLng customerPosition) {
    final destinationPosition = request.destinationPosition;
    final towingStage = request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed;
    return towingStage && destinationPosition != null
        ? destinationPosition
        : customerPosition;
  }

  double _estimatedTotalMetersForStage(AppRequest request, RouteData route) {
    if (request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed) {
      return (request.estimatedDistanceKm ?? (route.distanceMeters / 1000)) *
          1000;
    }

    return ((request.providerApproachDistanceKm ?? 0) > 0
            ? request.providerApproachDistanceKm!
            : (route.distanceMeters / 1000)) *
        1000;
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

  double? _providerHeadingRadians({
    required LatLng providerPosition,
    required LatLng customerPosition,
  }) {
    final rawHeading = _rawProviderHeadingRadians(
          providerPosition: providerPosition,
          customerPosition: customerPosition,
        ) ??
        _lastProviderHeadingRadians;

    if (rawHeading == null) return null;

    final smoothedHeading = _smoothHeadingRadians(rawHeading);
    _lastProviderHeadingRadians = smoothedHeading;
    return smoothedHeading;
  }

  double? _rawProviderHeadingRadians({
    required LatLng providerPosition,
    required LatLng customerPosition,
  }) {
    // Use movement direction if available
    if (_previousProviderPosition != null) {
      final distance = const Distance().as(
        LengthUnit.Meter,
        _previousProviderPosition!,
        providerPosition,
      );
      if (distance > 5) { // Only if moved significantly
        return _bearingRadians(_previousProviderPosition!, providerPosition) + (math.pi / 2);
      }
    }

    if (_routePoints.length >= 2) {
      var bestIndex = 0;
      var bestScore = double.infinity;

      for (var i = 0; i < _routePoints.length - 1; i++) {
        final current = _routePoints[i];
        final next = _routePoints[i + 1];
        final segmentDistance = _distanceToSegmentMeters(
          point: providerPosition,
          start: current,
          end: next,
        );
        final nextPointDistance = const Distance().as(
          LengthUnit.Meter,
          providerPosition,
          next,
        );
        final score = segmentDistance + (nextPointDistance * 0.08);
        if (score < bestScore) {
          bestScore = score;
          bestIndex = i;
        }
      }

      final segmentStart = _routePoints[bestIndex];
      final lookAheadPoint = _lookAheadPoint(bestIndex);
      if (segmentStart.latitude != lookAheadPoint.latitude ||
          segmentStart.longitude != lookAheadPoint.longitude) {
        return _bearingRadians(segmentStart, lookAheadPoint) + (math.pi / 2);
      }
    }

    return _bearingRadians(providerPosition, customerPosition) + (math.pi / 2);
  }

  LatLng _lookAheadPoint(int startIndex) {
    var accumulatedMeters = 0.0;

    for (var i = startIndex; i < _routePoints.length - 1; i++) {
      final current = _routePoints[i];
      final next = _routePoints[i + 1];
      accumulatedMeters += const Distance().as(
        LengthUnit.Meter,
        current,
        next,
      );

      if (accumulatedMeters >= 35 || i - startIndex >= 2) {
        return next;
      }
    }

    return _routePoints.last;
  }

  double _distanceToSegmentMeters({
    required LatLng point,
    required LatLng start,
    required LatLng end,
  }) {
    final pointX = point.longitude;
    final pointY = point.latitude;
    final startX = start.longitude;
    final startY = start.latitude;
    final endX = end.longitude;
    final endY = end.latitude;
    final deltaX = endX - startX;
    final deltaY = endY - startY;
    final lengthSquared = (deltaX * deltaX) + (deltaY * deltaY);

    if (lengthSquared == 0) {
      return const Distance().as(LengthUnit.Meter, point, start);
    }

    final projection =
        (((pointX - startX) * deltaX) + ((pointY - startY) * deltaY)) /
            lengthSquared;
    final t = projection.clamp(0.0, 1.0);
    final projected = LatLng(
      startY + (deltaY * t),
      startX + (deltaX * t),
    );

    return const Distance().as(LengthUnit.Meter, point, projected);
  }

  double _smoothHeadingRadians(double nextHeading) {
    final previousHeading = _lastProviderHeadingRadians;
    if (previousHeading == null) return nextHeading;

    final delta = _normalizeAngleRadians(nextHeading - previousHeading);
    final absDelta = delta.abs();
    final maxTurnStep = absDelta > 1.0
        ? 0.14
        : absDelta > 0.55
            ? 0.2
            : 0.3;
    final limitedDelta = delta.clamp(-maxTurnStep, maxTurnStep);
    final blendFactor = absDelta > 1.0
        ? 0.16
        : absDelta > 0.55
            ? 0.22
            : absDelta > 0.18
                ? 0.3
                : 0.42;
    return previousHeading + (limitedDelta * blendFactor);
  }

  double _normalizeAngleRadians(double angle) {
    var normalized = angle;
    while (normalized > math.pi) {
      normalized -= math.pi * 2;
    }
    while (normalized < -math.pi) {
      normalized += math.pi * 2;
    }
    return normalized;
  }

  double _bearingRadians(LatLng from, LatLng to) {
    final lat1 = _degreesToRadians(from.latitude);
    final lon1 = _degreesToRadians(from.longitude);
    final lat2 = _degreesToRadians(to.latitude);
    final lon2 = _degreesToRadians(to.longitude);
    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return math.atan2(y, x);
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.searching:
        return 'En attente d acceptation';
      case RequestStatus.accepted:
        return 'Mission acceptee';
      case RequestStatus.onTheWay:
        return 'En route';
      case RequestStatus.arrived:
        return 'Provider arrive';
      case RequestStatus.inService:
        return 'Vers destination';
      case RequestStatus.completed:
        return 'Mission terminee';
      case RequestStatus.cancelled:
        return 'Mission annulee';
    }
  }

  bool _hasAcceptedProvider(RequestStatus status) {
    return status == RequestStatus.accepted ||
        status == RequestStatus.onTheWay ||
        status == RequestStatus.arrived ||
        status == RequestStatus.inService ||
        status == RequestStatus.completed;
  }

  String _acceptedProviderMapLabel(String? providerName) {
    var safeName = (providerName ?? '').trim().toUpperCase();
    if (safeName.isEmpty) return 'DEPANNAGE';
    safeName = safeName.replaceFirst(RegExp(r'^PROVIDER\s+'), '');
    safeName = safeName.replaceFirst(RegExp(r'^DEPANNAGE\s+'), '');
    safeName = safeName.trim();
    if (safeName.isEmpty) return 'DEPANNAGE';
    return 'DEPANNAGE $safeName';
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

  Future<void> _callProvider(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  Future<void> _startNavigation(LatLng destination) async {
    final googleUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving&dir_action=navigate',
    );

    await launchUrl(googleUri, mode: LaunchMode.externalApplication);
  }

  String _routeStageTitle(AppRequest request) {
    if (request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed) {
      return 'Destination';
    }
    return 'Client';
  }

  String _routeStageValue(AppRequest request) {
    if (request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed) {
      return request.destination;
    }
    return request.pickupLabel;
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
    final actualProviderPosition =
        tracking?.providerPosition ?? request.providerPosition;
    final providerPosition =
        _renderedProviderPosition ?? actualProviderPosition;
    final routeTarget = _routeTarget(request, customerPosition);
    final nearbyProviders = request.status == RequestStatus.searching
        ? widget.store.nearbyProvidersForCustomer(
            customerPosition,
            requestId: request.id,
          )
        : const [];
    final offeredProviderId = widget.store.currentOfferedProviderId(request.id);
    final offerSecondsLeft = widget.store.offerSecondsRemaining(request.id);
    final acceptedProvider = _hasAcceptedProvider(request.status);
    final destinationStage = request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed;
    final providerAtPickup = providerPosition != null &&
        const Distance().as(
              LengthUnit.Meter,
              providerPosition,
              customerPosition,
            ) <=
            18;
    final customerMarkerOffset =
        providerAtPickup ? const Offset(-32, -14) : Offset.zero;
    final providerMarkerOffset =
        providerAtPickup ? const Offset(32, 10) : Offset.zero;
    final providerHeadingRadians = providerPosition == null
        ? null
        : _providerHeadingRadians(
            providerPosition: providerPosition,
            customerPosition: routeTarget,
          );

    final markers = <Marker>[];

    markers.add(
      Marker(
        point: customerPosition,
        width: 192,
        height: 160,
        child: _PinnedMarker(
          label: destinationStage ? 'Pick up' : 'Client',
          type: RoleMapMarkerType.customer,
          icon: Icons.person_pin_circle_rounded,
          color: Colors.red,
          compactLabel: true,
          offset: customerMarkerOffset,
        ),
      ),
    );

    if (destinationStage && request.destinationPosition != null) {
      markers.add(
        Marker(
          point: request.destinationPosition!,
          width: 192,
          height: 160,
          child: const _PinnedMarker(
            label: 'Destination',
            type: RoleMapMarkerType.destination,
            icon: Icons.place,
            color: Colors.red,
            compactLabel: true,
          ),
        ),
      );
    }

    if (providerPosition != null) {
      markers.add(
        Marker(
          point: providerPosition,
          width: 192,
          height: 160,
          child: _PinnedMarker(
            label: _acceptedProviderMapLabel(request.providerName),
            type: RoleMapMarkerType.provider,
            icon: Icons.car_repair_rounded,
            color: const Color(0xFFF59E0B),
            rotationRadians: providerHeadingRadians,
            compactLabel: true,
            offset: providerMarkerOffset,
          ),
        ),
      );
    } else {
      final seenProviderIds = <String>{};
      for (final provider in nearbyProviders) {
        if (!seenProviderIds.add(provider.id)) continue;
        final isTargeted = provider.id == offeredProviderId;
        markers.add(
          Marker(
            point: provider.position,
            width: 192,
            height: 160,
            child: _PinnedMarker(
              label: isTargeted ? 'Mission' : 'Depanneuse',
              type: RoleMapMarkerType.provider,
              icon: Icons.car_repair_rounded,
              color: isTargeted
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF6B7280),
              compactLabel: true,
            ),
          ),
        );
      }
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
                    title: acceptedProvider
                        ? _acceptedProviderMapLabel(request.providerName)
                        : 'Recherche du depanneur',
                    status: _statusLabel(request.status),
                    color: _statusColor(request.status),
                  ),
                ),
                const SizedBox(width: 10),
                _MapGlassButton(
                  icon: Icons.my_location_outlined,
                  onTap: providerPosition == null
                      ? null
                      : () {
                          setState(() => _followProvider = true);
                          _recenterRoute(providerPosition, routeTarget);
                        },
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
                          title: acceptedProvider ? 'Etat' : 'Offre',
                          value: acceptedProvider
                              ? 'Confirmee'
                              : '${offerSecondsLeft ?? '--'} s',
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
                    title: 'Pick up',
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
                    icon: Icons.route_rounded,
                    title: _routeStageTitle(request),
                    value: _routeStageValue(request),
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
                  if (!acceptedProvider)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await widget.store.cancelRequest(request.id);
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Annuler la demande'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _BottomActionIconButton(
                          icon: Icons.phone_outlined,
                          onPressed:
                              (request.providerPhone ?? '').trim().isEmpty
                                  ? null
                                  : () => _callProvider(request.providerPhone!),
                        ),
                        const SizedBox(width: 8),
                        _BottomActionIconButton(
                          icon: Icons.chat_bubble_outline,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  requestId: request.id,
                                  title: 'Chat provider',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _startNavigation(routeTarget),
                            icon: const Icon(Icons.navigation_outlined),
                            label: const Text('Ouvrir Maps'),
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
    required this.type,
    required this.icon,
    required this.color,
    this.rotationRadians,
    this.compactLabel = false,
    this.offset = Offset.zero,
  });

  final String label;
  final RoleMapMarkerType type;
  final IconData icon;
  final Color color;
  final double? rotationRadians;
  final bool compactLabel;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: RoleMapMarker(
        label: label,
        type: type,
        fallbackIcon: icon,
        color: color,
        size: 80,
        rotationRadians: rotationRadians,
        compactLabel: compactLabel,
      ),
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
