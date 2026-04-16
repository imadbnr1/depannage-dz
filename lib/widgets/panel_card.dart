import 'package:flutter/material.dart';

class PanelCard extends StatelessWidget {
  const PanelCard({
    super.key,
    required this.child,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
