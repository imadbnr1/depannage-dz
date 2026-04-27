import 'package:flutter/material.dart';

import 'role_map_marker.dart';

class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.markerType,
    this.assetPath,
  });

  final String label;
  final IconData icon;
  final Color color;
  final RoleMapMarkerType? markerType;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    if (markerType != null) {
      return RoleMapMarker(
        label: label,
        type: markerType!,
        fallbackIcon: icon,
        color: color,
        assetPath: assetPath,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}
