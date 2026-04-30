import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_snapshot.dart';

class RouteService {
  static final Map<String, RouteSnapshot> _cache = {};

  // Multiple routing servers to try (OSRM servers first, then alternatives)
  static const _osrmServers = [
    'https://router.project-osrm.org',
    'https://router.openstreetmap.de',
    'https://osrm-router.prod.aws.openstreetmap.de',
  ];

  // GraphHopper public API (better coverage in North Africa/Algeria)
  // Free tier: 500 requests/day. Get API key at https://www.graphhopper.com/
  static const _graphHopperServer = 'https://graphhopper.com/api/1/route';
  static const _graphHopperApiKey = '79eebee5-8dad-4cca-abeb-0612df7ba436';

  // Mapbox Directions API (better coverage in North Africa/Algeria)
  // Free tier: 100k requests/month. Get token at https://mapbox.com
  static const _mapboxServer = 'https://api.mapbox.com/directions/v5/mapbox/driving';
  static const _mapboxAccessToken = 'pk.eyJ1IjoiaW1lZGJuciIsImEiOiJjbW9rdXFwZ3QwYTNyMnhzYThoZ20wanEzIn0.TuolyERSKJzKpafwYr2APg';

  Future<RouteSnapshot> buildDrivingRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final safeOrigin = _safePoint(origin, fallback: const LatLng(36.7538, 3.0588));
    final safeDestination =
        _safePoint(destination, fallback: const LatLng(36.7538, 3.0588));

    final cacheKey = _buildCacheKey(safeOrigin, safeDestination);
    final cached = _cache[cacheKey];
    if (cached != null) {
      if (kDebugMode) {
        developer.log('RouteService: Using cached route',
          name: 'RouteService',
          level: 900,
        );
      }
      return cached;
    }

    // Try multiple OSRM servers first
    RouteSnapshot? result;
    String? lastError;
    for (final server in _osrmServers) {
      try {
        result = await _tryFetchRoute(server, safeOrigin, safeDestination);
        if (result != null && !result.isFallback) {
          if (kDebugMode) {
            developer.log('RouteService: Found valid route from $server',
              name: 'RouteService',
              level: 900,
            );
          }
          break;
        }
      } catch (e) {
        lastError = e.toString();
        if (kDebugMode) {
          developer.log('RouteService: Server $server failed: $e',
            name: 'RouteService',
            level: 700,
          );
        }
      }
    }

    // If OSRM failed, try GraphHopper (better coverage in North Africa/Algeria)
    if (result == null) {
      if (kDebugMode) {
        developer.log('RouteService: OSRM failed, trying GraphHopper...',
          name: 'RouteService',
          level: 700,
        );
      }
      try {
        result = await _tryFetchRouteGraphHopper(safeOrigin, safeDestination);
        if (result != null && !result.isFallback) {
          if (kDebugMode) {
            developer.log('RouteService: Found valid route from GraphHopper',
              name: 'RouteService',
              level: 900,
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('RouteService: GraphHopper failed: $e',
            name: 'RouteService',
            level: 700,
          );
        }
      }
    }

    // If GraphHopper also failed, try Mapbox (excellent coverage in North Africa)
    if (result == null) {
      if (kDebugMode) {
        developer.log('RouteService: GraphHopper failed, trying Mapbox...',
          name: 'RouteService',
          level: 700,
        );
      }
      try {
        result = await _tryFetchRouteMapbox(safeOrigin, safeDestination);
        if (result != null && !result.isFallback) {
          if (kDebugMode) {
            developer.log('RouteService: Found valid route from Mapbox',
              name: 'RouteService',
              level: 900,
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          developer.log('RouteService: Mapbox failed: $e',
            name: 'RouteService',
            level: 700,
          );
        }
      }
    }

    // If all servers failed and we got a fallback, retry once with a delay
    // This helps when servers are temporarily unavailable or rate-limited
    if (result == null) {
      if (kDebugMode) {
        developer.log('RouteService: All servers failed, retrying after 2s delay...',
          name: 'RouteService',
          level: 700,
        );
      }
      await Future.delayed(const Duration(seconds: 2));
      
      // Retry OSRM servers one more time
      for (final server in _osrmServers) {
        try {
          result = await _tryFetchRoute(server, safeOrigin, safeDestination);
          if (result != null && !result.isFallback) {
            if (kDebugMode) {
              developer.log('RouteService: Retry SUCCESS from $server',
                name: 'RouteService',
                level: 900,
              );
            }
            break;
          }
        } catch (e) {
          // Ignore retry errors
        }
      }
      
      // If OSRM still fails, retry GraphHopper
      if (result == null) {
        try {
          result = await _tryFetchRouteGraphHopper(safeOrigin, safeDestination);
          if (result != null && !result.isFallback) {
            if (kDebugMode) {
              developer.log('RouteService: Retry SUCCESS from GraphHopper',
                name: 'RouteService',
                level: 900,
              );
            }
          }
        } catch (e) {
          // Ignore
        }
      }
      
      // If GraphHopper still fails, retry Mapbox
      if (result == null) {
        try {
          result = await _tryFetchRouteMapbox(safeOrigin, safeDestination);
          if (result != null && !result.isFallback) {
            if (kDebugMode) {
              developer.log('RouteService: Retry SUCCESS from Mapbox',
                name: 'RouteService',
                level: 900,
              );
            }
          }
        } catch (e) {
          // Ignore
        }
      }
    }

    final finalResult = result ?? _fallback(safeOrigin, safeDestination);
    
    if (kDebugMode) {
      if (finalResult.isFallback) {
        developer.log(
          '⚠️ RouteService: FALLBACK (direct line) - OSRM failed, using ${finalResult.points.length} points',
          name: 'RouteService',
          level: 700,
        );
        developer.log(
          '⚠️ RouteService: This means the green line will be DIRECT, not following roads',
          name: 'RouteService',
          level: 700,
        );
        developer.log(
          '⚠️ RouteService: Possible causes: OSRM servers down, blocked by firewall/ISP, or no internet',
          name: 'RouteService',
          level: 700,
        );
        if (lastError != null) {
          developer.log('⚠️ RouteService: Last error: $lastError', name: 'RouteService', level: 700);
        }
      } else {
        developer.log(
          '✅ RouteService: SUCCESS (road route) - ${finalResult.points.length} points, ${finalResult.distanceKm.toStringAsFixed(2)} km',
          name: 'RouteService',
          level: 900,
        );
      }
    }
    
    _cache[cacheKey] = finalResult;
    return finalResult;
  }

  Future<RouteSnapshot?> _tryFetchRoute(
    String server,
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final url = Uri.parse(
        '$server/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson&steps=false',
      );

      if (kDebugMode) {
        developer.log('RouteService: Fetching from $server', 
          name: 'RouteService',
          level: 900,
        );
        developer.log('RouteService: URL: $url', 
          name: 'RouteService',
          level: 900,
        );
      }

      // For mobile, try direct connection first
      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirect(url);
          if (result != null) return result;
        } catch (e) {
          if (kDebugMode) {
            developer.log('RouteService: Direct fetch failed, trying CORS proxy: $e', 
              name: 'RouteService',
              level: 700,
            );
          }
        }
      }

      // Fallback to CORS proxy (required for web, used as fallback for mobile)
      return _fetchRouteWithCorsProxy(url);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: Error from $server: $e', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }
  }

  /// Fetch route from GraphHopper API
  /// GraphHopper often has better coverage in North Africa/Algeria than OSRM
  Future<RouteSnapshot?> _tryFetchRouteGraphHopper(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // GraphHopper API format: ?point=lat,lon&point=lat,lon&vehicle=car&key=xxx
      final url = Uri.parse(
        '$_graphHopperServer'
        '?point=${origin.latitude},${origin.longitude}'
        '&point=${destination.latitude},${destination.longitude}'
        '&vehicle=car'
        '&key=$_graphHopperApiKey'
        '&points_encoded=false'
        '&calc_points=true'
        '&instructions=false'
        '&elevation=false'
        '&optimize=false'
        '&locale=en',
      );

      if (kDebugMode) {
        developer.log('RouteService: Fetching from GraphHopper',
          name: 'RouteService',
          level: 900,
        );
        developer.log('RouteService: URL: $url',
          name: 'RouteService',
          level: 900,
        );
      }

      // For mobile, try direct connection first
      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirectGraphHopper(url);
          if (result != null) return result;
        } catch (e) {
          if (kDebugMode) {
            developer.log('RouteService: GraphHopper direct fetch failed, trying CORS proxy: $e',
              name: 'RouteService',
              level: 700,
            );
          }
        }
      }

      // Fallback to CORS proxy
      return _fetchRouteWithCorsProxyGraphHopper(url);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: Error from GraphHopper: $e',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirectGraphHopper(Uri url) async {
    final headers = {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json',
    };

    final response = await http.get(url, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: GraphHopper timeout (direct)',
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponseGraphHopper(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxyGraphHopper(Uri url) async {
    final effectiveUrl = Uri.parse(
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}',
    );

    if (kDebugMode) {
      developer.log('RouteService: GraphHopper using CORS proxy',
        name: 'RouteService',
        level: 900,
      );
    }

    final response = await http.get(effectiveUrl).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: GraphHopper timeout (CORS proxy)',
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponseGraphHopper(response, url);
  }

  /// Process GraphHopper API response (different format than OSRM)
  RouteSnapshot? _processRouteResponseGraphHopper(http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) {
      if (kDebugMode) {
        developer.log('RouteService: GraphHopper HTTP ${response.statusCode} - ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Check if response is JSON
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (kDebugMode) {
        developer.log('RouteService: GraphHopper invalid content-type: $contentType',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Prevent HTML error pages
    if (response.body.trimLeft().startsWith('<!DOCTYPE') ||
        response.body.trimLeft().startsWith('<html')) {
      if (kDebugMode) {
        developer.log('RouteService: GraphHopper HTML response instead of JSON',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      // GraphHopper response format: { paths: [ { points: { coordinates: [...] }, distance: xxx, time: xxx } ] }
      final paths = decoded['paths'];
      if (paths is! List || paths.isEmpty) {
        if (kDebugMode) {
          developer.log('RouteService: GraphHopper no paths in response',
            name: 'RouteService',
            level: 700,
          );
        }
        return null;
      }

      final first = paths.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      // Get points from GraphHopper format
      final pointsData = first['points'];
      if (pointsData is! Map<String, dynamic>) {
        return null;
      }

      final coordinates = pointsData['coordinates'];
      if (coordinates is! List || coordinates.isEmpty) {
        return null;
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
        if (kDebugMode) {
          developer.log('RouteService: GraphHopper not enough valid points (${cleaned.length})',
            name: 'RouteService',
            level: 700,
          );
        }
        return null;
      }

      // GraphHopper returns distance in meters and time in milliseconds
      final distanceMeters = _numToDouble(first['distance']) ?? 0;
      final timeMillis = _numToDouble(first['time']) ?? 0;
      final durationSeconds = timeMillis / 1000;

      final distanceKm = _isFinite(distanceMeters) && distanceMeters >= 0
          ? distanceMeters / 1000
          : const Distance().as(
              LengthUnit.Kilometer,
              cleaned.first,
              cleaned.last,
            );

      final durationMinutes = _isFinite(durationSeconds) && durationSeconds >= 0
          ? (durationSeconds / 60).round().clamp(1, 999)
          : ((distanceKm / 35) * 60).round().clamp(1, 999);

      if (kDebugMode) {
        developer.log('RouteService: GraphHopper SUCCESS - ${cleaned.length} points, ${distanceKm.toStringAsFixed(2)} km',
          name: 'RouteService',
          level: 900,
        );
      }

      return RouteSnapshot(
        points: cleaned,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        isFallback: false,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: GraphHopper JSON parse error: $e',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }
  }

  /// Fetch route from Mapbox Directions API
  /// Mapbox has excellent coverage in North Africa/Algeria
  Future<RouteSnapshot?> _tryFetchRouteMapbox(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      // Mapbox API format: /directions/v5/mapbox/driving/{lon},{lat};{lon},{lat}
      final url = Uri.parse(
        '$_mapboxServer/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}'
        '?access_token=$_mapboxAccessToken'
        '&geometries=geojson'
        '&overview=full'
        '&steps=false'
        '&alternatives=false',
      );

      if (kDebugMode) {
        developer.log('RouteService: Fetching from Mapbox',
          name: 'RouteService',
          level: 900,
        );
        developer.log('RouteService: URL: $url',
          name: 'RouteService',
          level: 900,
        );
      }

      // For mobile, try direct connection first
      if (!kIsWeb) {
        try {
          final result = await _fetchRouteDirectMapbox(url);
          if (result != null) return result;
        } catch (e) {
          if (kDebugMode) {
            developer.log('RouteService: Mapbox direct fetch failed, trying CORS proxy: $e',
              name: 'RouteService',
              level: 700,
            );
          }
        }
      }

      // Fallback to CORS proxy
      return _fetchRouteWithCorsProxyMapbox(url);
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: Error from Mapbox: $e',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirectMapbox(Uri url) async {
    final headers = {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json',
    };

    final response = await http.get(url, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: Mapbox timeout (direct)',
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponseMapbox(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxyMapbox(Uri url) async {
    final effectiveUrl = Uri.parse(
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}',
    );

    if (kDebugMode) {
      developer.log('RouteService: Mapbox using CORS proxy',
        name: 'RouteService',
        level: 900,
      );
    }

    final response = await http.get(effectiveUrl).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: Mapbox timeout (CORS proxy)',
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponseMapbox(response, url);
  }

  /// Process Mapbox Directions API response
  RouteSnapshot? _processRouteResponseMapbox(http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) {
      if (kDebugMode) {
        developer.log('RouteService: Mapbox HTTP ${response.statusCode}',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Check if response is JSON
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (kDebugMode) {
        developer.log('RouteService: Mapbox invalid content-type: $contentType',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Prevent HTML error pages
    if (response.body.trimLeft().startsWith('<!DOCTYPE') ||
        response.body.trimLeft().startsWith('<html')) {
      if (kDebugMode) {
        developer.log('RouteService: Mapbox HTML response instead of JSON',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      // Mapbox response format: { routes: [ { geometry: { coordinates: [...] }, distance: xxx, duration: xxx } ] }
      final routes = decoded['routes'];
      if (routes is! List || routes.isEmpty) {
        if (kDebugMode) {
          developer.log('RouteService: Mapbox no routes in response',
            name: 'RouteService',
            level: 700,
          );
        }
        return null;
      }

      final route = routes.first;
      if (route is! Map<String, dynamic>) {
        return null;
      }

      final geometry = route['geometry'];
      if (geometry is! Map<String, dynamic>) {
        return null;
      }

      final coordinates = geometry['coordinates'];
      if (coordinates is! List) {
        return null;
      }

      // Mapbox returns [lon, lat] pairs, convert to LatLng
      final points = <LatLng>[];
      for (final coord in coordinates) {
        if (coord is! List || coord.length < 2) continue;
        final lon = coord[0];
        final lat = coord[1];
        if (lon is! double || lat is! double) continue;
        points.add(LatLng(lat, lon)); // Note: LatLng expects (lat, lon)
      }

      if (points.length < 2) {
        return null;
      }

      final distance = route['distance'] as num?;
      final duration = route['duration'] as num?;

      final distanceKm = distance != null ? distance / 1000.0 : const Distance().as(
        LengthUnit.Kilometer,
        points.first,
        points.last,
      );
      final durationSeconds = duration?.toDouble() ?? 0;
      final durationMinutes = (durationSeconds / 60).round().clamp(1, 999);

      return RouteSnapshot(
        points: points,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        isFallback: false,
      );
    } catch (e) {
      if (kDebugMode) {
        developer.log('RouteService: Mapbox JSON parse error: $e',
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }
  }

  Future<RouteSnapshot?> _fetchRouteDirect(Uri url) async {
    final headers = {
      'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
      'Accept': 'application/json, application/geo+json',
    };

    final response = await http.get(url, headers: headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: Timeout (direct)', 
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponse(response, url);
  }

  Future<RouteSnapshot?> _fetchRouteWithCorsProxy(Uri url) async {
    final effectiveUrl = Uri.parse(
      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url.toString())}',
    );

    if (kDebugMode) {
      developer.log('RouteService: Using CORS proxy', 
        name: 'RouteService',
        level: 900,
      );
    }

    final response = await http.get(effectiveUrl).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          developer.log('RouteService: Timeout (CORS proxy)', 
            name: 'RouteService',
            level: 700,
          );
        }
        return http.Response('Timeout', 408);
      },
    );

    return _processRouteResponse(response, url);
  }

  RouteSnapshot? _processRouteResponse(http.Response response, Uri originalUrl) {
    if (response.statusCode != 200) {
      if (kDebugMode) {
        developer.log('RouteService: HTTP ${response.statusCode} - ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Check if response is JSON (not HTML error page)
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json') && 
        !contentType.contains('application/geo+json')) {
      if (kDebugMode) {
        developer.log('RouteService: Invalid content-type: $contentType', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    // Prevent HTML error pages from being parsed
    if (response.body.trimLeft().startsWith('<!DOCTYPE') || 
        response.body.trimLeft().startsWith('<html')) {
      if (kDebugMode) {
        developer.log('RouteService: HTML response instead of JSON', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      if (kDebugMode) {
        developer.log('RouteService: Invalid JSON structure', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    final routes = decoded['routes'];
    if (routes is! List || routes.isEmpty) {
      if (kDebugMode) {
        developer.log('RouteService: No routes in response', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    final first = routes.first;
    if (first is! Map<String, dynamic>) {
      return null;
    }

    final geometry = first['geometry'];
    if (geometry is! Map<String, dynamic>) {
      if (kDebugMode) {
        developer.log('RouteService: No geometry in route', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) {
      return null;
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
      if (kDebugMode) {
        developer.log('RouteService: Not enough valid points (${cleaned.length})', 
          name: 'RouteService',
          level: 700,
        );
      }
      return null;
    }

    final distanceMeters = _numToDouble(first['distance']) ?? 0;
    final durationSeconds = _numToDouble(first['duration']) ?? 0;

    final distanceKm = _isFinite(distanceMeters) && distanceMeters >= 0
        ? distanceMeters / 1000
        : const Distance().as(
            LengthUnit.Kilometer,
            cleaned.first,
            cleaned.last,
          );

    final durationMinutes = _isFinite(durationSeconds) && durationSeconds >= 0
        ? (durationSeconds / 60).round().clamp(1, 999)
        : ((distanceKm / 35) * 60).round().clamp(1, 999);

    if (kDebugMode) {
      developer.log('RouteService: SUCCESS - ${points.length} points, ${distanceKm.toStringAsFixed(2)} km', 
        name: 'RouteService',
        level: 900,
      );
    }

    return RouteSnapshot(
      points: cleaned,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      isFallback: false,
    );
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