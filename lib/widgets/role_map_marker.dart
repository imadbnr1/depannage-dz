import 'package:flutter/material.dart';

enum RoleMapMarkerType {
  customer,
  provider,
  destination,
}

class RoleMapMarker extends StatelessWidget {
  const RoleMapMarker({
    super.key,
    required this.label,
    required this.type,
    required this.fallbackIcon,
    required this.color,
    this.assetPath,
    this.size = 50,
    this.rotationRadians,
    this.showLabel = true,
    this.compactLabel = false,
  });

  final String label;
  final RoleMapMarkerType type;
  final IconData fallbackIcon;
  final Color color;
  final String? assetPath;
  final double size;
  final double? rotationRadians;
  final bool showLabel;
  final bool compactLabel;

  static const String customerAssetPath = 'assets/markers/customer_3d.png';
  static const String providerAssetPath = 'assets/markers/provider_3d.png';
  static const String destinationAssetPath = 'assets/markers/destination_3d.png';

  String get _resolvedAssetPath {
    if (assetPath != null && assetPath!.trim().isNotEmpty) {
      return assetPath!;
    }

    switch (type) {
      case RoleMapMarkerType.customer:
        return customerAssetPath;
      case RoleMapMarkerType.provider:
        return providerAssetPath;
      case RoleMapMarkerType.destination:
        return destinationAssetPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final labelWidget = Container(
      constraints: BoxConstraints(
        maxWidth: size * (compactLabel ? 1.4 : 1.8),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compactLabel ? 6 : 8,
        vertical: compactLabel ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: compactLabel ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) labelWidget,
        if (showLabel) const SizedBox(height: 2),
        SizedBox(
          width: size,
          height: size,
          child: Transform.rotate(
            angle: rotationRadians ?? 0,
            child: Image.asset(
              _resolvedAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.9),
                        color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    fallbackIcon,
                    color: Colors.white,
                    size: size * 0.55,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
