import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../firebase_options.dart';
import '../../models/route_snapshot.dart';

class MapProxyPlace {
  const MapProxyPlace({
    required this.displayName,
    required this.position,
  });

  final String displayName;
  final LatLng position;

  static MapProxyPlace? fromJson(Map<String, dynamic> json) {
    final displayName = (json['displayName'] ?? '').toString().trim();
    final lat = _numToDouble(json['lat']);
    final lng = _numToDouble(json['lng'] ?? json['lon']);
    if (displayName.isEmpty || lat == null || lng == null) return null;
    return MapProxyPlace(
      displayName: displayName,
      position: LatLng(lat, lng),
    );
  }
}

class MapProxyService {
  const MapProxyService();

  static String get _baseUrl {
    final override = _env(
      'MAP_PROXY_BASE_URL',
      const String.fromEnvironment('MAP_PROXY_BASE_URL'),
    );
    if (override.isNotEmpty) return _trimTrailingSlash(override);

    final region = _env(
      'FIREBASE_FUNCTIONS_REGION',
      const String.fromEnvironment(
        'FIREBASE_FUNCTIONS_REGION',
        defaultValue: 'us-central1',
      ),
    );
    final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
    return 'https://$region-$projectId.cloudfunctions.net';
  }

  Future<List<MapProxyPlace>> mapSearch(
    String query, {
    int limit = 6,
  }) async {
    final data = await _post('mapSearch', {
      'query': query,
      'limit': limit,
    });
    return _placesFromData(data);
  }

  Future<String?> reverseGeocode(LatLng position) async {
    final data = await _post('reverseGeocode', {
      'lat': position.latitude,
      'lng': position.longitude,
    });
    final displayName = (data?['displayName'] ?? '').toString().trim();
    return displayName.isEmpty ? null : displayName;
  }

  Future<List<MapProxyPlace>> nearbyPlaces(
    LatLng position, {
    int limit = 12,
  }) async {
    final data = await _post('nearbyPlaces', {
      'lat': position.latitude,
      'lng': position.longitude,
      'limit': limit,
    });
    return _placesFromData(data);
  }

  Future<RouteSnapshot?> routeDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final data = await _post('routeDirections', {
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {
        'lat': destination.latitude,
        'lng': destination.longitude,
      },
    });
    final route = data?['route'];
    if (route is! Map<String, dynamic>) return null;
    final pointsRaw = route['points'];
    if (pointsRaw is! List) return null;
    final points = <LatLng>[];
    for (final item in pointsRaw) {
      if (item is! Map<String, dynamic>) continue;
      final lat = _numToDouble(item['lat']);
      final lng = _numToDouble(item['lng'] ?? item['lon']);
      if (lat == null || lng == null) continue;
      points.add(LatLng(lat, lng));
    }
    if (points.length < 2) return null;
    return RouteSnapshot(
      points: points,
      distanceKm: _numToDouble(route['distanceKm']) ?? 0,
      durationMinutes:
          (_numToDouble(route['durationMinutes']) ?? 1).round().clamp(1, 999),
      isFallback: route['isFallback'] == true,
    );
  }

  Future<Map<String, dynamic>?> _post(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/$endpoint'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Map proxy unavailable for $endpoint.');
      }
      return null;
    }
  }

  List<MapProxyPlace> _placesFromData(Map<String, dynamic>? data) {
    final raw = data?['results'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MapProxyPlace.fromJson)
        .nonNulls
        .toList();
  }

  static String _env(String key, String dartDefineFallback) {
    final value = dotenv.env[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return dartDefineFallback.trim();
  }

  static String _trimTrailingSlash(String value) {
    var result = value.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}

double? _numToDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString());
}
