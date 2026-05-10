import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_snapshot.dart';

class RouteService {
  static final Map<String, RouteSnapshot> _cache = {};

  static const _osrmServers = [
    'https://router.project-osrm.org',
    'https://router.openstreetmap.de',
    'https://osrm-router.prod.aws.openstreetmap.de',
  ];

  static const _graphHopperServer = 'https://graphhopper.com/api/1/route';
  static String get _graphHopperApiKey => _env('GRAPHHOPPER_API_KEY',
      const String.fromEnvironment('GRAPHHOPPER_API_KEY'));

  static const _mapboxServer =
      'https://api.mapbox.com/directions/v5/mapbox/driving';
  static String get _mapboxAccessToken => _env('MAPBOX_ACCESS_TOKEN',
      const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'));

  static const _openRouteServiceServer =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static String get _openRouteServiceApiKey => _env(
        'OPENROUTESERVICE_API_KEY',
        const String.fromEnvironment('OPENROUTESERVICE_API_KEY'),
      );

  Future<RouteSnapshot> buildDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final safeOrigin =
        _safePoint(origin, fallback: const LatLng(36.7538, 3.0588));
    final safeDestination =
        _safePoint(destination, fallback: const LatLng(36.7538, 3.0588));

    final cacheKey = _buildCacheKey(safeOrigin, safeDestination);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    if (kIsWeb) {
      final fallback = _fallback(safeOrigin, safeDestination);
      _cache[cacheKey] = fallback;
      return fallback;
    }

    final futures = <Future<RouteSnapshot?>>[
      _tryFetchRouteOpenRouteService(safeOrigin, safeDestination),
      for (final server in _osrmServers)
        _tryFetchRoute(server, safeOrigin, safeDestination),
      _tryFetchRouteGraphHopper(safeOrigin, safeDestination),
      _tryFetchRouteMapbox(safeOrigin, safeDestination),
    ];

    RouteSnapshot? result;
    try {
      result = await _firstSuccessful(futures);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: All routing servers failed: $e',
            name: 'RouteService', level: 700);
      }
    }

    final finalResult = result ?? _fallback(safeOrigin, safeDestination);

    if (kDebugMode) {
      if (finalResult.isFallback) {
        developer.log(
            '⚠️ RouteService: FALLBACK (direct line) - all routing sources failed',
            name: 'RouteService',
            level: 700);
      } else {
        developer.log(
            '✅ RouteService: SUCCESS - ${finalResult.points.length} pts, '
            '${finalResult.distanceKm.toStringAsFixed(2)} km',
            name: 'RouteService',
            level: 900);
      }
    }

    _cache[cacheKey] = finalResult;
    return finalResult;
  }

  // ✅ FIX 1: Properly handle the case where all futures return null (no exception)
  Future<RouteSnapshot?> _firstSuccessful(
      List<Future<RouteSnapshot?>> futures) async {
    final completer = Completer<RouteSnapshot?>();
    int remaining = futures.length;

    for (final future in futures) {
      future.then((value) {
        if (!completer.isCompleted && value != null) {
          completer.complete(value);
        }
      }).catchError((e) {
        if (kDebugMode) {
          developer.log('RouteService: A future errored: $e',
              name: 'RouteService', level: 700);
        }
      }).whenComplete(() {
        remaining--;
        // All futures settled and none returned a valid result → complete with null
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }

  // ==================== OpenRouteService ====================
  Future<RouteSnapshot?> _tryFetchRouteOpenRouteService(
      LatLng origin, LatLng destination) async {
    final apiKey = _openRouteServiceApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('$_openRouteServiceServer'
          '?start=${origin.longitude},${origin.latitude}'
          '&end=${destination.longitude},${destination.latitude}'
          '&api_key=$apiKey'
          '&format=geojson'
          '&geometry=true'
          '&instructions=false'
          '&geometry_simplify=false');

      final response = await http.get(url, headers: {
        'User-Agent': 'DepannageDZGraduation/1.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8),
          onTimeout: () => http.Response('Timeout', 408));

      return _processOpenRouteServiceResponse(response);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: ORS error: $e',
            name: 'RouteService', level: 700);
      }
      return null;
    }
  }

  RouteSnapshot? _processOpenRouteServiceResponse(http.Response response) {
    if (response.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final features = decoded['features'];
      if (features is! List || features.isEmpty) return null;

      final geometry = features.first['geometry'];
      if (geometry is! Map<String, dynamic>) return null;

      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return null;

      final points = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is! List || coord.length < 2) continue;
        // ✅ FIX 2: Use _numToDouble instead of `is double` — JSON ints are valid coords
        final lon = _numToDouble(coord[0]);
        final lat = _numToDouble(coord[1]);
        if (lat == null || lon == null || !_isFinite(lat) || !_isFinite(lon)) {
          continue;
        }
        points.add(LatLng(lat, lon));
      }
      if (points.length < 2) return null;

      final properties = features.first['properties'];
      final segments = properties?['segments'];
      double distanceKm;
      int durationMinutes;

      if (segments is List && segments.isNotEmpty) {
        final seg = segments.first;
        final distM = _numToDouble(seg['distance']);
        final durS = _numToDouble(seg['duration']);
        distanceKm = distM != null
            ? distM / 1000
            : const Distance()
                .as(LengthUnit.Kilometer, points.first, points.last);
        durationMinutes = durS != null
            ? (durS / 60).round().clamp(1, 999)
            : ((distanceKm / 35) * 60).round().clamp(1, 999);
      } else {
        distanceKm = const Distance()
            .as(LengthUnit.Kilometer, points.first, points.last);
        durationMinutes = ((distanceKm / 35) * 60).round().clamp(1, 999);
      }

      if (kDebugMode) {
        developer.log(
            'RouteService: ORS SUCCESS - ${points.length} pts, '
            '${distanceKm.toStringAsFixed(2)} km',
            name: 'RouteService',
            level: 900);
      }
      return RouteSnapshot(
          points: points,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          isFallback: false);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: ORS parse error: $e',
            name: 'RouteService', level: 700);
      }
      return null;
    }
  }

  // ==================== OSRM ====================
  Future<RouteSnapshot?> _tryFetchRoute(
      String server, LatLng origin, LatLng destination) async {
    try {
      final url = Uri.parse('$server/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=false');

      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirect(url);
          if (result != null) return result;
        } catch (_) {}
      }
      return _fetchRouteWithCorsProxy(url);
    } catch (e) {
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirect(Uri url) async {
    final response = await http.get(url, headers: {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json, application/geo+json',
    }).timeout(const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponse(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxy(Uri url) async {
    final proxyUrl = Uri.parse(
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}');
    final response = await http.get(proxyUrl).timeout(
        const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponse(response, url);
  }

  RouteSnapshot? _processRouteResponse(
      http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) return null;

    final ct = response.headers['content-type'] ?? '';
    if (!ct.contains('application/json') &&
        !ct.contains('application/geo+json')) {
      return null;
    }

    final body = response.body.trimLeft();
    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return null;

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) return null;

    final first = routes.first;
    if (first is! Map<String, dynamic>) return null;

    final geometry = first['geometry'];
    if (geometry is! Map<String, dynamic>) return null;

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return null;

    final points = <LatLng>[];
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
    if (cleaned.length < 2) return null;

    final distanceMeters = _numToDouble(first['distance']) ?? 0;
    final durationSeconds = _numToDouble(first['duration']) ?? 0;

    final distanceKm = _isFinite(distanceMeters) && distanceMeters >= 0
        ? distanceMeters / 1000
        : const Distance()
            .as(LengthUnit.Kilometer, cleaned.first, cleaned.last);
    final durationMinutes = _isFinite(durationSeconds) && durationSeconds >= 0
        ? (durationSeconds / 60).round().clamp(1, 999)
        : ((distanceKm / 35) * 60).round().clamp(1, 999);

    return RouteSnapshot(
        points: cleaned,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        isFallback: false);
  }

  // ==================== GraphHopper ====================
  Future<RouteSnapshot?> _tryFetchRouteGraphHopper(
      LatLng origin, LatLng destination) async {
    final apiKey = _graphHopperApiKey;
    if (apiKey.isEmpty) return null;

    try {
      final url = Uri.parse('$_graphHopperServer'
          '?point=${origin.latitude},${origin.longitude}'
          '&point=${destination.latitude},${destination.longitude}'
          '&vehicle=car'
          '&key=$apiKey'
          '&points_encoded=false'
          '&calc_points=true'
          '&instructions=false'
          '&elevation=false'
          '&optimize=false'
          '&locale=en');

      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirectGraphHopper(url);
          if (result != null) return result;
        } catch (_) {}
      }
      return _fetchRouteWithCorsProxyGraphHopper(url);
    } catch (e) {
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirectGraphHopper(Uri url) async {
    final response = await http.get(url, headers: {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponseGraphHopper(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxyGraphHopper(Uri url) async {
    final proxyUrl = Uri.parse(
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}');
    final response = await http.get(proxyUrl).timeout(
        const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponseGraphHopper(response, url);
  }

  RouteSnapshot? _processRouteResponseGraphHopper(
      http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final paths = decoded['paths'];
      if (paths is! List || paths.isEmpty) return null;
      final first = paths.first;
      if (first is! Map<String, dynamic>) return null;
      final pointsData = first['points'];
      if (pointsData is! Map<String, dynamic>) return null;
      final coordinates = pointsData['coordinates'];
      if (coordinates is! List || coordinates.isEmpty) return null;

      final points = <LatLng>[];
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
      if (cleaned.length < 2) return null;

      final distanceMeters = _numToDouble(first['distance']) ?? 0;
      final timeMillis = _numToDouble(first['time']) ?? 0;
      final durationSeconds = timeMillis / 1000;

      final distanceKm = _isFinite(distanceMeters) && distanceMeters >= 0
          ? distanceMeters / 1000
          : const Distance()
              .as(LengthUnit.Kilometer, cleaned.first, cleaned.last);
      final durationMinutes = _isFinite(durationSeconds) && durationSeconds >= 0
          ? (durationSeconds / 60).round().clamp(1, 999)
          : ((distanceKm / 35) * 60).round().clamp(1, 999);

      return RouteSnapshot(
          points: cleaned,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          isFallback: false);
    } catch (e) {
      return null;
    }
  }

  // ==================== Mapbox ====================
  Future<RouteSnapshot?> _tryFetchRouteMapbox(
      LatLng origin, LatLng destination) async {
    final accessToken = _mapboxAccessToken;
    if (accessToken.isEmpty) return null;

    try {
      final url =
          Uri.parse('$_mapboxServer/${origin.longitude},${origin.latitude};'
              '${destination.longitude},${destination.latitude}'
              '?access_token=$accessToken'
              '&geometries=geojson'
              '&overview=full'
              '&steps=false'
              '&alternatives=false');

      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirectMapbox(url);
          if (result != null) return result;
        } catch (_) {}
      }
      return _fetchRouteWithCorsProxyMapbox(url);
    } catch (e) {
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirectMapbox(Uri url) async {
    final response = await http.get(url, headers: {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponseMapbox(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxyMapbox(Uri url) async {
    final proxyUrl = Uri.parse(
        'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}');
    final response = await http.get(proxyUrl).timeout(
        const Duration(seconds: 6),
        onTimeout: () => http.Response('Timeout', 408));
    return _processRouteResponseMapbox(response, url);
  }

  RouteSnapshot? _processRouteResponseMapbox(
      http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) return null;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final route = routes.first;
      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic>) return null;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List) return null;

      final points = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is! List || coord.length < 2) continue;
        // ✅ FIX 2 applied here too: _numToDouble handles both int and double
        final lon = _numToDouble(coord[0]);
        final lat = _numToDouble(coord[1]);
        if (lon == null || lat == null || !_isFinite(lon) || !_isFinite(lat)) {
          continue;
        }
        points.add(LatLng(lat, lon));
      }
      if (points.length < 2) return null;

      final distance = _numToDouble(route['distance']);
      final duration = _numToDouble(route['duration']);
      final distanceKm = distance != null
          ? distance / 1000.0
          : const Distance()
              .as(LengthUnit.Kilometer, points.first, points.last);
      final durationMinutes = duration != null
          ? (duration / 60).round().clamp(1, 999)
          : ((distanceKm / 35) * 60).round().clamp(1, 999);

      return RouteSnapshot(
          points: points,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          isFallback: false);
    } catch (e) {
      return null;
    }
  }

  // ==================== Helpers ====================
  String _buildCacheKey(LatLng a, LatLng b) {
    String r(double v) => v.toStringAsFixed(5);
    return '${r(a.latitude)},${r(a.longitude)}|${r(b.latitude)},${r(b.longitude)}';
  }

  RouteSnapshot _fallback(LatLng origin, LatLng destination) {
    final safeOrigin =
        _safePoint(origin, fallback: const LatLng(36.7538, 3.0588));
    final safeDestination =
        _safePoint(destination, fallback: const LatLng(36.7538, 3.0588));
    final distanceKm =
        const Distance().as(LengthUnit.Kilometer, safeOrigin, safeDestination);
    final points = _sanitizePoints([safeOrigin, safeDestination]);
    return RouteSnapshot(
        points: points.length >= 2 ? points : [safeOrigin, safeDestination],
        distanceKm: _isFinite(distanceKm) ? distanceKm : 0,
        durationMinutes: ((_isFinite(distanceKm) ? distanceKm : 0) / 35 * 60)
            .round()
            .clamp(1, 999),
        isFallback: true);
  }

  LatLng _safePoint(LatLng point, {required LatLng fallback}) {
    if (_isFinite(point.latitude) && _isFinite(point.longitude)) return point;
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

  bool _isFinite(double value) => value.isFinite && !value.isNaN;

  static String _env(String key, String dartDefineFallback) {
    final value = dotenv.env[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return dartDefineFallback.trim();
  }
}
