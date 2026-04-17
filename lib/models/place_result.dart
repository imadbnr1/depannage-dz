import 'package:latlong2/latlong.dart';

class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.position,
  });

  final String name;
  final LatLng position;
}