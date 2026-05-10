import 'package:auto_rescue/core/i18n/app_language_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.compact = false,
    this.backgroundColor,
  });

  final bool compact;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppLanguageController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = compact || constraints.maxWidth < 96;
        final maxWidth = tight ? 48.0 : 92.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: tight ? 42 : 64,
            maxWidth: maxWidth,
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Language',
            initialValue: ctrl.locale.languageCode,
            onSelected: (code) => ctrl.setLanguage(code),
            child: Container(
              height: compact ? 38 : 42,
              padding: EdgeInsets.symmetric(
                horizontal: tight ? 9 : 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFE2D6C2).withValues(alpha: 0.86),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 14,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _flag(ctrl.locale.languageCode),
                      style: TextStyle(fontSize: compact ? 16 : 20),
                    ),
                    if (!tight) ...[
                      const SizedBox(width: 7),
                      Text(
                        _label(ctrl.locale.languageCode),
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 2),
                    ],
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: compact ? 15 : 18,
                      color: const Color(0xFF0F172A),
                    ),
                  ],
                ),
              ),
            ),
            itemBuilder: (context) => [
              _buildItem('fr', 'FR', 'Francais'),
              _buildItem('en', 'EN', 'English'),
              _buildItem('ar', 'AR', 'Arabic'),
            ],
          ),
        );
      },
    );
  }

  PopupMenuItem<String> _buildItem(String code, String flag, String label) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              flag,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  String _flag(String code) {
    switch (code) {
      case 'en':
        return 'EN';
      case 'ar':
        return 'AR';
      default:
        return 'FR';
    }
  }

  String _label(String code) {
    switch (code) {
      case 'en':
        return 'EN';
      case 'ar':
        return 'AR';
      default:
        return 'FR';
    }
  }
}
