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
    this.size = 50,
    this.rotationRadians,
    this.showLabel = true,
    this.compactLabel = false,
    this.showPulse = false,
  });

  final String label;
  final RoleMapMarkerType type;
  final IconData fallbackIcon;
  final Color color;
  final double size;
  final double? rotationRadians;
  final bool showLabel;
  final bool compactLabel;
  final bool showPulse;

  static const double outerSize = 88;
  static const double labelHeight = 22;

  @override
  Widget build(BuildContext context) {
    final markerSize = size.clamp(42.0, 52.0);
    final marker = Transform.rotate(
      angle: rotationRadians ?? 0,
      child: _FallbackMarkerIcon(
        color: color,
        fallbackIcon: fallbackIcon,
        size: markerSize,
      ),
    );

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 28,
            child: SizedBox(
              width: 76,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (showPulse) _MarkerPulseRing(color: color),
                  marker,
                ],
              ),
            ),
          ),
          if (showLabel)
            Positioned(
              top: 0,
              left: 2,
              right: 2,
              child: Center(
                child: _MarkerLabel(
                  label: label,
                  compact: compactLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MarkerLabel extends StatelessWidget {
  const _MarkerLabel({
    required this.label,
    required this.compact,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 84),
      child: Container(
        height: RoleMapMarker.labelHeight,
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9),
        alignment: Alignment.center,
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
            fontSize: compact ? 9 : 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _MarkerPulseRing extends StatefulWidget {
  const _MarkerPulseRing({
    required this.color,
  });

  final Color color;

  @override
  State<_MarkerPulseRing> createState() => _MarkerPulseRingState();
}

class _MarkerPulseRingState extends State<_MarkerPulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOut.transform(_controller.value);
        return Transform.scale(
          scale: 0.72 + (t * 0.34),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: (1 - t) * 0.08),
              border: Border.all(
                color: widget.color.withValues(alpha: (1 - t) * 0.34),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallbackMarkerIcon extends StatelessWidget {
  const _FallbackMarkerIcon({
    required this.color,
    required this.fallbackIcon,
    required this.size,
  });

  final Color color;
  final IconData fallbackIcon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.92),
              color,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.34),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          fallbackIcon,
          color: Colors.white,
          size: size * 0.52,
        ),
      ),
    );
  }
}
