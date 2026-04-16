import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_search_result.dart';

class PlaceSearchService {
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
      headers: {
        'User-Agent': 'DepannageDZGraduation/1.0 (education project)',
        'Accept': 'application/json',
      },
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
}