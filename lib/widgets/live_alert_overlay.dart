import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showLiveAlertOverlay({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  String? imageUrl,
  Color accentColor = const Color(0xFF2563EB),
  Curve transitionCurve = Curves.easeOutCubic,
  Offset slideBegin = const Offset(0, 0.05),
  double scaleBegin = 0.94,
  String primaryLabel = 'Voir',
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  Duration? autoPrimaryAfter,
}) async {
  Timer? timer;

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Alerte',
    barrierColor: const Color(0x660B1220),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, __) {
      if (autoPrimaryAfter != null && onPrimary != null) {
        timer = Timer(autoPrimaryAfter, () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          onPrimary();
        });
      }

      return SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dialogWidth = constraints.maxWidth > 420
                    ? 360.0
                    : (constraints.maxWidth - 24).clamp(280.0, 360.0);
                final stackedActions =
                    dialogWidth < 330 || secondaryLabel != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Container(
                    width: dialogWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFFCF7),
                          Color(0xFFF7EFE2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x260B1220),
                          blurRadius: 30,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColor.withValues(alpha: 0.14),
                                accentColor.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              accentColor.withValues(alpha: 0.14),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      icon,
                                      size: 30,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            height: 1.05,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (imageUrl != null && imageUrl.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(22),
                                    child: Stack(
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          height: 176,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                        Positioned(
                                          left: 12,
                                          top: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.46,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Annonce visuelle',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (stackedActions)
                                Column(
                                  children: [
                                    if (secondaryLabel != null) ...[
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            timer?.cancel();
                                            Navigator.of(context).pop();
                                            onSecondary?.call();
                                          },
                                          child: Text(secondaryLabel),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton(
                                        onPressed: () {
                                          timer?.cancel();
                                          Navigator.of(context).pop();
                                          onPrimary?.call();
                                        },
                                        child: Text(primaryLabel),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    if (secondaryLabel != null) ...[
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            timer?.cancel();
                                            Navigator.of(context).pop();
                                            onSecondary?.call();
                                          },
                                          child: Text(secondaryLabel),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () {
                                          timer?.cancel();
                                          Navigator.of(context).pop();
                                          onPrimary?.call();
                                        },
                                        child: Text(primaryLabel),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: transitionCurve);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: slideBegin,
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: scaleBegin, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );

  timer?.cancel();
}
