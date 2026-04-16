import 'package:latlong2/latlong.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.requestId,
    required this.customerPosition,
    required this.providerPosition,
  });

  final String requestId;
  final LatLng customerPosition;
  final LatLng? providerPosition;

  TrackingSnapshot copyWith({
    LatLng? customerPosition,
    LatLng? providerPosition,
  }) {
    return TrackingSnapshot(
      requestId: requestId,
      customerPosition: customerPosition ?? this.customerPosition,
      providerPosition: providerPosition ?? this.providerPosition,
    );
  }
}

abstract class TrackingRepository {
  Stream<TrackingSnapshot?> watchTracking(String requestId);
  TrackingSnapshot? currentTracking(String requestId);
  Future<void> setTracking(TrackingSnapshot snapshot);
  Future<void> clearTracking(String requestId);

  TrackingSnapshot? getTracking(String requestId) {
  return null;
}
}
