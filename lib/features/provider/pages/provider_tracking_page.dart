import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/services/realtime_tracking_service.dart';
import '../../../core/services/route_service.dart';
import '../../../models/app_request.dart';
import '../../../models/request_status.dart';
import '../../../models/route_snapshot.dart';
import '../../../state/app_store.dart';
import '../../../widgets/role_map_marker.dart';
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
  final RouteService _routeService = RouteService();
  RealtimeTrackingService? _trackingService;

  StreamSubscription? _trackingSub;
  Timer? _routeTimer;
  Timer? _simulationTimer;
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
  bool _devToolsVisible = false;
  bool _simulationRunning = false;
  String _simulationMode = 'Approche client';
  int _simulationIndex = 0;
  int _devTapCount = 0;
  DateTime? _lastDevTapAt;
  bool _followProvider = true;
  bool _routeIsFallback = false;
  double _panelExtent = 0.30;

  @override
  void initState() {
    super.initState();
    _initRealTimeTracking();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final request = widget.store.findRequest(widget.requestId);
      if (request != null) {
        _syncAnimatedProviderPosition(request, immediate: true);
      }
      _scheduleRouteUpdate();
    });

    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove &&
          event.source != MapEventSource.mapController) {
        setState(() => _followProvider = false);
      }
    });
  }

  Future<void> _initRealTimeTracking() async {
    _trackingService = RealtimeTrackingService();

    // Start real-time GPS tracking if provider is on active mission
    final providerUid = widget.store.currentProviderUid;
    if (providerUid != null) {
      await _trackingService?.startTracking(providerUid);
      debugPrint(
          '🛰️ Real-time GPS tracking started (updates every 3 seconds)');
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChanged);
    _trackingSub?.cancel();
    _trackingService?.stopTracking();
    _routeTimer?.cancel();
    _simulationTimer?.cancel();
    _providerAnimationTimer?.cancel();
    super.dispose();
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    final request = widget.store.findRequest(widget.requestId);
    if (request != null) {
      _syncAnimatedProviderPosition(request);
      _scheduleRouteUpdate();
    }
    setState(() {});
  }

  void _syncAnimatedProviderPosition(
    AppRequest request, {
    bool immediate = false,
  }) {
    // During simulation, the simulation timer handles position updates
    // Don't interfere with the animation system
    if (_simulationRunning) return;

    final tracking = widget.store.trackingFor(widget.requestId);
    final targetPosition = tracking?.providerPosition ??
        widget.store.providerCurrentPosition ??
        request.providerPosition;

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

    // ✅ ONLY animate for simulation mode - real tracking uses direct GPS position
    if (!_simulationRunning) {
      // For real tracking: instantly update to actual GPS position (no animation)
      _providerAnimationTimer?.cancel();
      _renderedProviderPosition = targetPosition;

      // Calculate heading from actual movement
      final bearing = _bearingRadians(currentPosition, targetPosition);
      final markerRotation = bearing + (math.pi / 2);

      setState(() {
        _lastProviderHeadingRadians = markerRotation;
      });

      if (_followProvider) {
        _mapController.move(
          targetPosition,
          _mapController.camera.zoom,
          id: 'follow',
        );
      }
      return;
    }

    // ✅ For simulation only: follow green polyline route
    final startedAt = DateTime.now();
    const minDurationMs = 400;
    const maxDurationMs = 1600;
    const idealSpeed = 80;
    final calculatedDuration = (distanceMeters / idealSpeed * 1000).round();
    final durationMs = calculatedDuration.clamp(minDurationMs, maxDurationMs);
    final duration = Duration(milliseconds: durationMs);
    const animationCurve = Curves.easeInOutCubic;

    _providerAnimationTimer?.cancel();

    // ✅ Calculate correct bearing between actual positions
    final bearing = _bearingRadians(currentPosition, targetPosition);
    final markerRotation = bearing + (math.pi / 2);

    _providerAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final elapsed = DateTime.now().difference(startedAt);
        final t =
            (elapsed.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        final easedT = animationCurve.transform(t);

        final newPosition = _lerpLatLng(
          currentPosition,
          targetPosition,
          easedT,
        );

        setState(() {
          _renderedProviderPosition = newPosition;
          _lastProviderHeadingRadians = markerRotation;
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

          // ✅ Continue only for simulation
          if (_simulationRunning &&
              _routePoints.isNotEmpty &&
              _simulationIndex < _routePoints.length - 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _syncAnimatedProviderPosition(request);
            });
          }
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

  void _scheduleRouteUpdate() {
    // Don't update route during simulation - route is already calculated
    // Updating during simulation causes unnecessary API calls and can result in fallback (red line)
    if (_simulationRunning) return;

    _routeTimer?.cancel();
    _routeTimer = Timer(const Duration(milliseconds: 350), _loadRoute);
  }

  void _handleHiddenDevTap() {
    final now = DateTime.now();
    final lastTapAt = _lastDevTapAt;
    if (lastTapAt == null ||
        now.difference(lastTapAt) > const Duration(seconds: 2)) {
      _devTapCount = 0;
    }

    _lastDevTapAt = now;
    _devTapCount += 1;

    if (_devTapCount < 6) return;

    _devTapCount = 0;
    _lastDevTapAt = null;
    if (!mounted) return;

    setState(() {
      _devToolsVisible = !_devToolsVisible;
    });
  }

  Future<void> _toggleSimulation() async {
    if (_simulationRunning) {
      _simulationTimer?.cancel();
      if (!mounted) return;
      setState(() => _simulationRunning = false);
      return;
    }

    if (_routePoints.length < 2) {
      await _loadRoute();
    }
    if (_routePoints.length < 2 || !mounted) return;

    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    if (_simulationIndex <= 0 || _simulationIndex >= _routePoints.length) {
      _simulationIndex = 0;
      await widget.store.devSetProviderTrackingPosition(
        request.id,
        _routePoints.first,
      );
    }

    _simulationTimer?.cancel();
    setState(() => _simulationRunning = true);

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 70), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentRequest = widget.store.findRequest(widget.requestId);
      if (currentRequest == null || _routePoints.length < 2) {
        timer.cancel();
        if (mounted) {
          setState(() => _simulationRunning = false);
        }
        return;
      }

      _simulationIndex += 1;
      if (_simulationIndex >= _routePoints.length) {
        _simulationIndex = _routePoints.length - 1;
        await widget.store.devSetProviderTrackingPosition(
          currentRequest.id,
          _routePoints[_simulationIndex],
        );
        timer.cancel();
        if (mounted) {
          setState(() => _simulationRunning = false);
        }
        return;
      }

      await widget.store.devSetProviderTrackingPosition(
        currentRequest.id,
        _routePoints[_simulationIndex],
      );
    });
  }

  Future<void> _startNavigation(LatLng destination) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=driving'
      '&dir_action=navigate',
    );

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _simulateTowToDestination() async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    _simulationTimer?.cancel();
    if (mounted) {
      setState(() {
        _simulationRunning = false;
        _simulationMode = 'Vers destination';
      });
    }

    if (request.status == RequestStatus.accepted) {
      await widget.store.advanceMission(request.id);
    }

    final afterAccepted = widget.store.findRequest(widget.requestId);
    if (afterAccepted == null) return;
    if (afterAccepted.status == RequestStatus.onTheWay) {
      await widget.store.advanceMission(afterAccepted.id);
    }

    final arrivedRequest = widget.store.findRequest(widget.requestId);
    if (arrivedRequest == null) return;

    await widget.store.devSetProviderTrackingPosition(
      arrivedRequest.id,
      arrivedRequest.customerPosition,
    );

    if (arrivedRequest.status == RequestStatus.arrived) {
      await widget.store.advanceMission(arrivedRequest.id);
    }

    _simulationIndex = 0;
    _lastRouteStart = null;
    _lastRouteTarget = null;
    _lastRouteStatus = null;
    await _loadRoute();
    await _toggleSimulation();
  }

  Future<void> _resetSimulation() async {
    _simulationTimer?.cancel();
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    if (_routePoints.length < 2) {
      await _loadRoute();
    }
    if (_routePoints.isEmpty) return;

    _simulationIndex = 0;
    await widget.store.devSetProviderTrackingPosition(
      request.id,
      _routePoints.first,
    );

    if (!mounted) return;
    setState(() {
      _simulationRunning = false;
      _simulationMode = 'Approche client';
    });
  }

  Future<void> _loadRoute() async {
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) return;

    if (request.status == RequestStatus.completed ||
        request.status == RequestStatus.cancelled) {
      if (!mounted) return;
      setState(() {
        _routePoints = [];
        _routeDistanceMeters = null;
        _routeDurationSeconds = null;
        _routeProgress = null;
        _routeIsFallback = false;
        _loadingRoute = false;
        _lastRouteStart = null;
        _lastRouteTarget = null;
        _lastRouteStatus = request.status;
      });
      return;
    }

    final tracking = widget.store.trackingFor(widget.requestId);
    final providerPosition = tracking?.providerPosition ??
        widget.store.providerCurrentPosition ??
        request.providerPosition;
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
      final route = await _routeService.buildDrivingRoute(
        origin: providerPosition,
        destination: routeTarget,
      );

      if (!mounted) return;

      if (route.points.isEmpty || route.isFallback) {
        // Only use fallback (direct line) if route service completely failed
        // This should rarely happen with RouteService's robust error handling
        setState(() {
          _routePoints = route.points;
          _routeDistanceMeters = route.distanceKm * 1000;
          _routeDurationSeconds = route.durationMinutes * 60;
          _routeProgress = null;
          _routeIsFallback = route.isFallback;
        });
      } else {
        final estimatedTotalMeters =
            _estimatedTotalMetersForStage(request, route);
        final progress = estimatedTotalMeters <= 0
            ? null
            : ((estimatedTotalMeters - (route.distanceKm * 1000)) /
                    estimatedTotalMeters)
                .clamp(0.0, 1.0);

        setState(() {
          _routePoints = route.points;
          _routeDistanceMeters = route.distanceKm * 1000;
          _routeDurationSeconds = route.durationMinutes * 60;
          _routeProgress = progress;
          _routeIsFallback = false;
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
        _routeIsFallback = true;
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

  double _estimatedTotalMetersForStage(
      AppRequest request, RouteSnapshot route) {
    if (request.status == RequestStatus.arrived ||
        request.status == RequestStatus.inService ||
        request.status == RequestStatus.completed) {
      return (request.estimatedDistanceKm ?? route.distanceKm) * 1000;
    }

    return ((request.providerApproachDistanceKm ?? 0) > 0
            ? request.providerApproachDistanceKm!
            : route.distanceKm) *
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
      if (distance > 5) {
        // Only if moved significantly
        return _bearingRadians(_previousProviderPosition!, providerPosition) +
            (math.pi / 2);
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
        return 'Recherche provider';
      case RequestStatus.accepted:
        return 'Mission acceptee';
      case RequestStatus.onTheWay:
        return 'En route';
      case RequestStatus.arrived:
        return 'Arrive chez le client';
      case RequestStatus.inService:
        return 'Vers destination';
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
        return 'Demarrer mission';
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
    return request.customerName;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final request = widget.store.findRequest(widget.requestId);
    if (request == null) {
      return Scaffold(
        body: Center(
          child: Text(strings.t('mission_introuvable')),
        ),
      );
    }

    final tracking = widget.store.trackingFor(widget.requestId);
    final customerPosition =
        tracking?.customerPosition ?? request.customerPosition;
    final actualProviderPosition = tracking?.providerPosition ??
        widget.store.providerCurrentPosition ??
        request.providerPosition;
    final providerPosition =
        _renderedProviderPosition ?? actualProviderPosition;
    final routeTarget = _routeTarget(request, customerPosition);
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
    // ignore: unused_local_variable
    final providerMarkerOffset =
        providerAtPickup ? const Offset(32, 10) : Offset.zero;
    // ignore: unused_local_variable
    final providerHeadingRadians = providerPosition == null
        ? null
        : _providerHeadingRadians(
            providerPosition: providerPosition,
            customerPosition: routeTarget,
          );

    final markers = <Marker>[];

    if (!destinationStage) {
      markers.add(
        Marker(
          point: customerPosition,
          width: 82,
          height: 82,
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
    }

    if (destinationStage && request.destinationPosition != null) {
      markers.add(
        Marker(
          point: request.destinationPosition!,
          width: 82,
          height: 82,
          child: const _PinnedMarker(
            label: 'Dest',
            type: RoleMapMarkerType.destination,
            icon: Icons.place,
            color: Colors.red,
            compactLabel: true,
          ),
        ),
      );
    }

    if (providerPosition != null) {
      // PROVIDER MARKER - CONSISTENT SIZE WITH OTHER MARKERS
      markers.add(
        Marker(
          point: providerPosition,
          width: 50,
          height: 50,
          alignment: Alignment.topCenter,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.directions_car, color: Colors.white, size: 24),
          ),
        ),
      );
    }

    final safe = MediaQuery.paddingOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compactHeight = screenHeight < 620;
    final minExtent = compactHeight ? 0.24 : 0.20;
    final initialExtent = compactHeight ? 0.36 : 0.30;
    final maxExtent = compactHeight ? 0.82 : 0.70;
    final clampedExtent = _panelExtent.clamp(minExtent, maxExtent).toDouble();
    final floatingBottom = (screenHeight * clampedExtent) + safe.bottom + 14;
    final topInset = safe.top;
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
                        color: _loadingRoute
                            ? Colors.blue
                            : (_routeIsFallback
                                ? const Color(0xFFFF0000)
                                : const Color.fromRGBO(25, 167, 25, 1)),
                      ),
                    ],
                  ),
                if (_loadingRoute)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _routePoints.isNotEmpty
                            ? _routePoints.first
                            : customerPosition,
                        width: 40,
                        height: 40,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
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
                  child: GestureDetector(
                    onTap: _handleHiddenDevTap,
                    child: _TopTrackingBanner(
                      title: request.customerName,
                      status: _statusLabel(request.status),
                      color: _statusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_devToolsVisible)
            Positioned(
              top: topInset + 84,
              right: 12,
              child: _DevSimulationCard(
                running: _simulationRunning,
                simulationMode: _simulationMode,
                onStartPause: _toggleSimulation,
                onTowSimulation: _simulateTowToDestination,
                onReset: _resetSimulation,
              ),
            ),
          Positioned(
            right: 12 + safe.right,
            bottom: floatingBottom,
            child: _MapGlassButton(
              icon: Icons.my_location_outlined,
              onTap: () {
                final currentPos = widget.store.providerCurrentPosition ??
                    actualProviderPosition;
                if (currentPos == null) {
                  widget.store.requestProviderLocation();
                  return;
                }

                setState(() => _followProvider = true);
                _mapController.move(currentPos, 16);
              },
            ),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              if ((notification.extent - _panelExtent).abs() > 0.002) {
                setState(() => _panelExtent = notification.extent);
              }
              return false;
            },
            child: DraggableScrollableSheet(
              minChildSize: minExtent,
              initialChildSize: initialExtent,
              maxChildSize: maxExtent,
              snap: true,
              snapSizes: [minExtent, initialExtent, maxExtent],
              builder: (context, scrollController) {
                return _TrackingOverlayCard(
                  child: ListView(
                    controller: scrollController,
                    padding: EdgeInsets.only(bottom: safe.bottom + 4),
                    children: [
                      const _SheetHandle(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _InfoBox(
                                  title: strings.t('distance'),
                                  value: _formatDistance(),
                                  accent: const Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoBox(
                                  title: strings.t('eta'),
                                  value: _formatEta(),
                                  accent: const Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoBox(
                                  title: strings.t('action'),
                                  value: _canAdvance(request.status)
                                      ? strings.t('available')
                                      : strings.t('blocked'),
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
                            title: strings.t('pick_up'),
                            value: request.pickupLabel,
                          ),
                          const SizedBox(height: 6),
                          _SummaryInlineRow(
                            icon: Icons.route_rounded,
                            title: _routeStageTitle(request),
                            value: _routeStageValue(request),
                          ),
                          const SizedBox(height: 6),
                          _SummaryInlineRow(
                            icon: Icons.phone_outlined,
                            title: strings.t('client'),
                            value: request.customerPhone,
                          ),
                          if ((request.providerApproachFee ?? 0) > 0) ...[
                            const SizedBox(height: 6),
                            _SummaryInlineRow(
                              icon: Icons.payments_outlined,
                              title: strings.t('access_fee'),
                              value:
                                  '${request.providerApproachFee!.toStringAsFixed(0)} DA',
                            ),
                          ],
                          if (_loadingRoute && _routePoints.isEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                strings.t('calculating_route'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          Column(
                            children: [
                              Row(
                                children: [
                                  _BottomActionIconButton(
                                    icon: Icons.phone_outlined,
                                    onPressed: request.customerPhone
                                            .trim()
                                            .isEmpty
                                        ? null
                                        : () =>
                                            _callClient(request.customerPhone),
                                  ),
                                  const SizedBox(width: 8),
                                  _BottomActionIconButton(
                                    icon: Icons.chat_bubble_outline,
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ChatPage(
                                            requestId: request.id,
                                            title: strings.t('chat_client'),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _startNavigation(routeTarget),
                                      icon:
                                          const Icon(Icons.navigation_outlined),
                                      label:
                                          Text(strings.t('open_google_maps')),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _canAdvance(request.status)
                                      ? () => widget.store
                                          .advanceMission(widget.requestId)
                                      : null,
                                  icon: const Icon(Icons.flag_outlined),
                                  label: Text(_actionLabel(request.status)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                );
              },
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
    this.compactLabel = false,
    this.offset = Offset.zero,
    // ignore: unused_element_parameter
    this.rotationRadians,
  });

  final String label;
  final RoleMapMarkerType type;
  final IconData icon;
  final Color color;
  // ignore: unused_field
  final double? rotationRadians;
  final bool compactLabel;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final marker = SizedBox(
      width: 70,
      height: 70,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: RoleMapMarker(
          label: label,
          type: type,
          fallbackIcon: icon,
          color: color,
          size: 46,
          rotationRadians: rotationRadians,
          compactLabel: compactLabel,
        ),
      ),
    );

    return Transform.translate(
      offset: offset,
      child: marker,
    );
  }
}

class _DevSimulationCard extends StatelessWidget {
  const _DevSimulationCard({
    required this.running,
    required this.simulationMode,
    required this.onStartPause,
    required this.onTowSimulation,
    required this.onReset,
  });

  final bool running;
  final String simulationMode;
  final Future<void> Function() onStartPause;
  final Future<void> Function() onTowSimulation;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dev Simulation',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap banner 6 times to hide',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mode: $simulationMode',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onStartPause,
              icon: Icon(running ? Icons.pause : Icons.play_arrow),
              label: Text(running ? 'Pause simulation' : 'Start simulation'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTowSimulation,
              icon: const Icon(Icons.alt_route),
              label: const Text('Simuler vers destination'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset to route start'),
            ),
          ),
        ],
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(10),
        ),
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
