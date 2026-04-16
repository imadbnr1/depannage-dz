import 'package:latlong2/latlong.dart';

class RouteSnapshot {
  const RouteSnapshot({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.isFallback,
  });

  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final bool isFallback;
}