import 'package:latlong2/latlong.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.requestId,
    required this.customerPosition,
    this.providerPosition,
  });

  final String requestId;
  final LatLng customerPosition;
  final LatLng? providerPosition;

  TrackingSnapshot copyWith({
    String? requestId,
    LatLng? customerPosition,
    LatLng? providerPosition,
    bool clearProviderPosition = false,
  }) {
    return TrackingSnapshot(
      requestId: requestId ?? this.requestId,
      customerPosition: customerPosition ?? this.customerPosition,
      providerPosition: clearProviderPosition
          ? null
          : (providerPosition ?? this.providerPosition),
    );
  }
}