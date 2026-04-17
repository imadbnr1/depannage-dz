import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/place_result.dart';

class GeocodingService {
  static const _userAgent = 'depannage-dz-app';

  Future<List<PlaceResult>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '6',
        'countrycodes': 'dz',
        'addressdetails': '1',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      return const [];
    }

    final List<dynamic> data = jsonDecode(response.body);

    return data.map((item) {
      return PlaceResult(
        name: (item['display_name'] ?? '').toString(),
        position: LatLng(
          double.tryParse((item['lat'] ?? '').toString()) ?? 0,
          double.tryParse((item['lon'] ?? '').toString()) ?? 0,
        ),
      );
    }).where((p) {
      return p.name.isNotEmpty &&
          p.position.latitude != 0 &&
          p.position.longitude != 0;
    }).toList();
  }

  Future<String?> reverseGeocode(LatLng position) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'jsonv2',
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) return null;

    final Map<String, dynamic> data = jsonDecode(response.body);
    return (data['display_name'] ?? '').toString();
  }
}