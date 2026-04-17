import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteData {
  const RouteData({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

class RoutingService {
  Future<RouteData?> getRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'] as List<dynamic>?;

    if (routes == null || routes.isEmpty) return null;

    final first = routes.first as Map<String, dynamic>;
    final geometry = first['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;

    if (coordinates == null) return null;

    final points = coordinates.map<LatLng>((c) {
      final pair = c as List<dynamic>;
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();

    return RouteData(
      points: points,
      distanceMeters: ((first['distance'] ?? 0) as num).toDouble(),
      durationSeconds: ((first['duration'] ?? 0) as num).toDouble(),
    );
  }
}