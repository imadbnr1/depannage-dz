import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherService {
  Future<void> callPhone(String phone) async {
    if (phone.isEmpty) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> openGoogleMaps({
    required LatLng destination,
    LatLng? origin,
  }) async {
    final destinationValue =
        '${destination.latitude},${destination.longitude}';

    final url = origin == null
        ? 'https://www.google.com/maps/dir/?api=1&destination=$destinationValue&travelmode=driving'
        : 'https://www.google.com/maps/dir/?api=1&origin=${origin.latitude},${origin.longitude}&destination=$destinationValue&travelmode=driving';

    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}