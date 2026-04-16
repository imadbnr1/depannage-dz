import 'package:latlong2/latlong.dart';

class ProviderAgent {
  const ProviderAgent({
    required this.id,
    required this.name,
    required this.phone,
    required this.position,
    required this.isOnline,
    required this.isBusy,
    required this.rating,
    required this.ratingCount,
    required this.vehicleType,
    required this.plate,
    required this.missionsCompleted,
    required this.isVerified,
    required this.avatarText,
  });

  final String id;
  final String name;
  final String phone;
  final LatLng position;
  final bool isOnline;
  final bool isBusy;
  final double rating;
  final int ratingCount;
  final String vehicleType;
  final String plate;
  final int missionsCompleted;
  final bool isVerified;
  final String avatarText;

  ProviderAgent copyWith({
    String? id,
    String? name,
    String? phone,
    LatLng? position,
    bool? isOnline,
    bool? isBusy,
    double? rating,
    int? ratingCount,
    String? vehicleType,
    String? plate,
    int? missionsCompleted,
    bool? isVerified,
    String? avatarText,
  }) {
    return ProviderAgent(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      vehicleType: vehicleType ?? this.vehicleType,
      plate: plate ?? this.plate,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      isVerified: isVerified ?? this.isVerified,
      avatarText: avatarText ?? this.avatarText,
    );
  }
}