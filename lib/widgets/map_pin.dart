import 'package:flutter/material.dart';

import 'role_map_marker.dart';

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.markerType,
    this.showPulse = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final RoleMapMarkerType? markerType;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return RoleMapMarker(
      label: label,
      type: markerType ?? RoleMapMarkerType.destination,
      fallbackIcon: icon,
      color: color,
      compactLabel: true,
      showPulse: showPulse,
    );
  }
}
