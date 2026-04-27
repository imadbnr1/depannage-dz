import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_search_result.dart';

class PlaceSearchService {
  static const _headers = {
    'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
    'Accept': 'application/json',
  };

  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) return [];

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

    final response = await http.get(
      uri,
      headers: _headers,
    );

    if (response.statusCode != 200) {
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

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) return null;

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
}
