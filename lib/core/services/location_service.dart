import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class AppLocationResult {
  const AppLocationResult({
    required this.position,
    required this.message,
    required this.isRealLocation,
  });

  final LatLng position;
  final String message;
  final bool isRealLocation;
}

class LocationService {
  Future<AppLocationResult> getCurrentPosition({
    required LatLng fallback,
    required String successMessage,
    required String deniedMessage,
    required String disabledMessage,
    required String errorMessage,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return AppLocationResult(
          position: fallback,
          message: disabledMessage,
          isRealLocation: false,
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return AppLocationResult(
          position: fallback,
          message: deniedMessage,
          isRealLocation: false,
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return AppLocationResult(
          position: fallback,
          message: 'Permission refusee definitivement',
          isRealLocation: false,
        );
      }

      final gps = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      final lat = gps.latitude;
      final lng = gps.longitude;

      if (!lat.isFinite || !lng.isFinite || lat.isNaN || lng.isNaN) {
        return AppLocationResult(
          position: fallback,
          message: errorMessage,
          isRealLocation: false,
        );
      }

      return AppLocationResult(
        position: LatLng(lat, lng),
        message: successMessage,
        isRealLocation: true,
      );
    } catch (_) {
      return AppLocationResult(
        position: fallback,
        message: errorMessage,
        isRealLocation: false,
      );
    }
  }
}