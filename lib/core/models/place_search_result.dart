import 'package:latlong2/latlong.dart';

class PlaceSearchResult {
  const PlaceSearchResult({
    required this.displayName,
    required this.position,
  });

  final String displayName;
  final LatLng position;

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse((json['lat'] ?? '').toString()) ?? 0;
    final lon = double.tryParse((json['lon'] ?? '').toString()) ?? 0;

    return PlaceSearchResult(
      displayName: (json['display_name'] ?? '').toString(),
      position: LatLng(lat, lon),
    );
  }
}