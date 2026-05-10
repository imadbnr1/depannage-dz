import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_search_result.dart';
import 'map_proxy_service.dart';

class PlaceSearchService {
  static const _headers = {
    'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
    'Accept': 'application/json',
  };
  final MapProxyService _mapProxy = const MapProxyService();

  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return [];

    final proxied = await _mapProxy.mapSearch(cleaned, limit: 5);
    if (proxied.isNotEmpty) {
      return proxied
          .map((place) => PlaceSearchResult(
                displayName: place.displayName,
                position: place.position,
              ))
          .toList();
    }
    if (kIsWeb) return [];

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': cleaned,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '5',
      },
    );

    try {
      return await _searchDirect(uri);
    } catch (e) {
      return [];
    }
  }

  Future<List<PlaceSearchResult>> _searchDirect(Uri uri) async {
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 6));

    if (response.statusCode != 200) {
      throw Exception('Recherche de destination indisponible.');
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw Exception('Recherche de destination indisponible.');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(PlaceSearchResult.fromJson)
        .toList();
  }

  Future<String?> reverseLookupNearestNamedPlace(LatLng position) async {
    final proxied = await _mapProxy.reverseGeocode(position);
    if (proxied != null && proxied.isNotEmpty) return proxied;
    if (kIsWeb) return null;

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
      },
    );

    try {
      return await _reverseLookupDirect(uri);
    } catch (e) {
      return null;
    }
  }

  Future<String?> _reverseLookupDirect(Uri uri) async {
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) return null;

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) return null;

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return null;

    return _extractAddressFromReverseData(data);
  }

  String? _extractAddressFromReverseData(Map<String, dynamic> data) {
    final address = data['address'];
    if (address is Map<String, dynamic>) {
      final roadCandidates = [
        address['road'],
        address['residential'],
        address['pedestrian'],
        address['footway'],
        address['path'],
        address['cycleway'],
      ];

      for (final value in roadCandidates) {
        final road = (value ?? '').toString().trim();
        if (road.isEmpty) continue;

        final houseNumber = (address['house_number'] ?? '').toString().trim();
        final suburb = (address['suburb'] ?? address['neighbourhood'] ?? '')
            .toString()
            .trim();
        final town =
            (address['town'] ?? address['city'] ?? address['village'] ?? '')
                .toString()
                .trim();

        final parts = <String>[
          if (houseNumber.isNotEmpty) houseNumber,
          road,
          if (suburb.isNotEmpty && suburb.toLowerCase() != road.toLowerCase())
            suburb,
          if (town.isNotEmpty &&
              town.toLowerCase() != road.toLowerCase() &&
              town.toLowerCase() != suburb.toLowerCase())
            town,
        ];

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }

      final candidates = [
        address['neighbourhood'],
        address['suburb'],
        address['village'],
        address['town'],
        address['city'],
        address['county'],
        address['state_district'],
        address['state'],
      ];

      for (final value in candidates) {
        final text = (value ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
    }

    final displayName = (data['display_name'] ?? '').toString().trim();
    if (displayName.isEmpty) return null;

    final firstPart = displayName.split(',').first.trim();
    if (firstPart.isNotEmpty) return firstPart;
    return displayName;
  }

  /// Fetch nearby places/points of interest around a location
  /// Optimized for towing/roadside assistance app - prioritizes automotive services
  Future<List<PlaceSearchResult>> fetchNearbyPlaces(
    LatLng position, {
    int limit = 12,
  }) async {
    final proxied = await _mapProxy.nearbyPlaces(position, limit: limit);
    if (proxied.isNotEmpty) {
      return proxied
          .map((place) => PlaceSearchResult(
                displayName: place.displayName,
                position: place.position,
              ))
          .toList();
    }
    if (kIsWeb) return _getAutomotiveFallbackSuggestions(position);

    try {
      // Use Overpass API to get automotive-related places
      // Prioritize: garages, mechanics, tire shops, gas stations, car dealerships, auto electricians
      final overpassQuery = '''
        [out:json][timeout:5];
        (
          node["shop"~"car|car_repair|car_parts|tire|vulcanizer|motorcycle|motorcycle_repair"](around:5000,${position.latitude},${position.longitude});
          node["amenity"="fuel"](around:5000,${position.latitude},${position.longitude});
          node["amenity"="car_wash"](around:5000,${position.latitude},${position.longitude});
          node["craft"="car_repair"](around:5000,${position.latitude},${position.longitude});
          node["shop"="electronics"](around:5000,${position.latitude},${position.longitude})["electronics"~"car_audio|car_accessories"];
          node["office"~"insurance"]["insurance"~"car|vehicle|auto"](around:5000,${position.latitude},${position.longitude});
          way["shop"~"car|car_repair|car_parts|tire"](around:5000,${position.latitude},${position.longitude});
          way["amenity"="fuel"](around:5000,${position.latitude},${position.longitude});
          relation["shop"~"car|car_repair"](around:5000,${position.latitude},${position.longitude});
        );
        out body;
        >;
        out skel qt;
      ''';

      final uri = Uri.https(
        'overpass-api.de',
        '/api/interpreter',
        {'data': overpassQuery},
      );

      final response = await http
          .get(
            uri,
            headers: _headers,
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _getAutomotiveFallbackSuggestions(position);
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        return _getAutomotiveFallbackSuggestions(position);
      }

      final elements = data['elements'] as List<dynamic>?;
      if (elements == null) {
        return _getAutomotiveFallbackSuggestions(position);
      }

      final results = <PlaceSearchResult>[];
      for (final element in elements.take(limit)) {
        if (element is Map<String, dynamic>) {
          final tags = element['tags'] as Map<String, dynamic>?;
          final lat = (element['lat'] as num?)?.toDouble();
          final lon = (element['lon'] as num?)?.toDouble();

          if (tags != null && lat != null && lon != null) {
            final name = _getPlaceName(tags);
            final type = _getAutomotivePlaceType(tags);

            results.add(PlaceSearchResult(
              displayName: '$name - $type',
              position: LatLng(lat, lon),
            ));
          }
        }
      }

      if (results.isEmpty) {
        return _getAutomotiveFallbackSuggestions(position);
      }

      return results;
    } catch (e) {
      return _getAutomotiveFallbackSuggestions(position);
    }
  }

  /// Extract name from tags with smart fallbacks
  String _getPlaceName(Map<String, dynamic> tags) {
    // Try common name fields in order
    final nameFields = ['name', 'brand', 'operator', 'name:fr', 'name:ar'];
    for (final field in nameFields) {
      final value = tags[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    // No name found, generate descriptive name
    final shop = tags['shop']?.toString() ?? '';
    final amenity = tags['amenity']?.toString() ?? '';
    final craft = tags['craft']?.toString() ?? '';

    if (shop == 'car_repair' || craft == 'car_repair') return 'Garage';
    if (shop == 'car_parts') return 'Pièces Auto';
    if (shop == 'tire') return 'Pneumaticien';
    if (amenity == 'fuel') return 'Station Service';
    if (amenity == 'car_wash') return 'Lavage Auto';
    if (shop == 'car') return 'Concessionnaire';

    return 'Service Auto';
  }

  /// Get human-readable type for automotive places
  String _getAutomotivePlaceType(Map<String, dynamic> tags) {
    final shop = tags['shop']?.toString() ?? '';
    final amenity = tags['amenity']?.toString() ?? '';
    final craft = tags['craft']?.toString() ?? '';

    // Specific types
    if (shop == 'car_repair' || craft == 'car_repair') {
      final specialty = tags['car_repair']?.toString() ?? '';
      if (specialty == 'engine') return 'Mécanicien Moteur';
      if (specialty == 'transmission') return 'Boîte de Vitesses';
      if (specialty == 'electrical') return 'Électricien Auto';
      if (specialty == 'bodywork') return 'Carrossier';
      if (specialty == 'glass') return 'Pare-brise';
      return 'Garage/Réparation';
    }

    if (shop == 'car_parts') return 'Pièces Détachées';
    if (shop == 'tire') return 'Pneus & Jantes';
    if (amenity == 'fuel') return 'Carburant';
    if (amenity == 'car_wash') return 'Lavage';
    if (shop == 'car') {
      final brand = tags['brand'] ?? 'Auto';
      return 'Concessionnaire $brand';
    }

    return 'Service Automobile';
  }

  /// Get fallback suggestions based on known automotive areas in Algeria
  Future<List<PlaceSearchResult>> _getAutomotiveFallbackSuggestions(
      LatLng position) async {
    // Known automotive zones, industrial areas, and commercial zones in Algeria
    // These areas typically have many garages and auto services
    final automotiveZones = [
      ('Zone Industrielle Batna', 35.5489, 6.1850),
      ('Cité Mechaniciens Batna', 35.5520, 6.1680),
      ('Route de Barika (Garages)', 35.5450, 6.1500),
      ('Zone Commerciale Kechida', 35.5600, 6.1900),
      ('Djerma - Route Nationale', 35.5333, 6.2500),
      ('Fesdis - Zone Artisanale', 35.5833, 6.2833),
      ('Tazoult - Zone Industrielle', 35.5889, 6.3167),
      ('Barika - Route Nationale 3', 35.3833, 5.8333),
      ('Merouana - Centre Commercial', 35.4667, 5.8833),
      ('Ngaous - Zone Artisanale', 35.6833, 5.9167),
      ('Oued Chaaba - Garages', 35.5167, 6.0500),
      ('Theniet El Ahmar - Route Principale', 35.4500, 5.7500),
    ];

    // Sort by distance from current position
    automotiveZones.sort((a, b) {
      final distA = _distanceKm(
        position.latitude,
        position.longitude,
        a.$2,
        a.$3,
      );
      final distB = _distanceKm(
        position.latitude,
        position.longitude,
        b.$2,
        b.$3,
      );
      return distA.compareTo(distB);
    });

    return automotiveZones.take(8).map((zone) {
      return PlaceSearchResult(
        displayName: zone.$1,
        position: LatLng(zone.$2, zone.$3),
      );
    }).toList();
  }

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}
