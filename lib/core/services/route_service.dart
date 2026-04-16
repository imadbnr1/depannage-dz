import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_snapshot.dart';

class RouteService {
  static final Map<String, RouteSnapshot> _cache = {};

  Future<RouteSnapshot> buildDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final safeOrigin = _safePoint(origin, fallback: const LatLng(36.7538, 3.0588));
    final safeDestination =
        _safePoint(destination, fallback: const LatLng(36.7538, 3.0588));

    final cacheKey = _buildCacheKey(safeOrigin, safeDestination);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${safeOrigin.longitude},${safeOrigin.latitude};'
        '${safeDestination.longitude},${safeDestination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        return _fallback(safeOrigin, safeDestination);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _fallback(safeOrigin, safeDestination);
      }

      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        return _fallback(safeOrigin, safeDestination);
      }

      final first = routes.first;
      if (first is! Map<String, dynamic>) {
        return _fallback(safeOrigin, safeDestination);
      }

      final geometry = first['geometry'];
      if (geometry is! Map<String, dynamic>) {
        return _fallback(safeOrigin, safeDestination);
      }

      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.isEmpty) {
        return _fallback(safeOrigin, safeDestination);
      }

      final List<LatLng> points = [];
      for (final item in coordinates) {
        if (item is List && item.length >= 2) {
          final lon = _numToDouble(item[0]);
          final lat = _numToDouble(item[1]);

          if (lat != null && lon != null && _isFinite(lat) && _isFinite(lon)) {
            points.add(LatLng(lat, lon));
          }
        }
      }

      final cleaned = _sanitizePoints(points);

      if (cleaned.length < 2) {
        return _fallback(safeOrigin, safeDestination);
      }

      final distanceMeters = _numToDouble(first['distance']) ?? 0;
      final durationSeconds = _numToDouble(first['duration']) ?? 0;

      final distanceKm = _isFinite(distanceMeters) && distanceMeters >= 0
          ? distanceMeters / 1000
          : const Distance().as(
              LengthUnit.Kilometer,
              safeOrigin,
              safeDestination,
            );

      final durationMinutes = _isFinite(durationSeconds) && durationSeconds >= 0
          ? (durationSeconds / 60).round().clamp(1, 999)
          : ((distanceKm / 35) * 60).round().clamp(1, 999);

      final result = RouteSnapshot(
        points: cleaned,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        isFallback: false,
      );

      _cache[cacheKey] = result;
      return result;
    } catch (_) {
      return _fallback(safeOrigin, safeDestination);
    }
  }

  String _buildCacheKey(LatLng a, LatLng b) {
    String r(double v) => v.toStringAsFixed(5);
    return '${r(a.latitude)},${r(a.longitude)}|${r(b.latitude)},${r(b.longitude)}';
  }

  RouteSnapshot _fallback(LatLng origin, LatLng destination) {
    final safeOrigin = _safePoint(origin, fallback: const LatLng(36.7538, 3.0588));
    final safeDestination =
        _safePoint(destination, fallback: const LatLng(36.7538, 3.0588));

    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      safeOrigin,
      safeDestination,
    );

    final points = _sanitizePoints([safeOrigin, safeDestination]);

    return RouteSnapshot(
      points: points.length >= 2 ? points : [safeOrigin, safeDestination],
      distanceKm: _isFinite(distanceKm) ? distanceKm : 0,
      durationMinutes: ((_isFinite(distanceKm) ? distanceKm : 0) / 35 * 60)
          .round()
          .clamp(1, 999),
      isFallback: true,
    );
  }

  LatLng _safePoint(LatLng point, {required LatLng fallback}) {
    if (_isFinite(point.latitude) && _isFinite(point.longitude)) {
      return point;
    }
    return fallback;
  }

  List<LatLng> _sanitizePoints(List<LatLng> points) {
    final cleaned = points
        .where((p) => _isFinite(p.latitude) && _isFinite(p.longitude))
        .toList();

    if (cleaned.isEmpty) return [];
    if (cleaned.length == 1) return [cleaned.first, cleaned.first];
    return cleaned;
  }

  double? _numToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  bool _isFinite(double value) {
    return value.isFinite && !value.isNaN;
  }
}