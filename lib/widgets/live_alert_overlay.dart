import 'dart:async';

import 'package:flutter/material.dart';

Future<void> showLiveAlertOverlay({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  String? imageUrl,
  Color accentColor = const Color(0xFF2563EB),
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
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 220),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 22,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFF3F4F6),
                                child: Icon(
                                  icon,
                                  size: 28,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
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
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  timer?.cancel();
}
