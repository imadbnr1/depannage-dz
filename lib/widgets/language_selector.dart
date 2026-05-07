import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_rescue/core/i18n/app_language_controller.dart';

// Replace with your actual import path:

class LanguageSelector extends StatelessWidget {
  final bool compact;
  final Color? backgroundColor;
  const LanguageSelector({super.key, this.compact = false, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AppLanguageController>();

    return PopupMenuButton<String>(
      initialValue: ctrl.locale.languageCode,
      onSelected: (code) => ctrl.setLanguage(code),
      // The button itself — flag + current language label
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _flag(ctrl.locale.languageCode),
              style: TextStyle(
                fontSize: compact ? 16 : 20,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _label(ctrl.locale.languageCode),
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: compact ? 14 : 18,
            ),
          ],
        ),
      ),
      // The 3 language options
      itemBuilder: (context) => [
        _buildItem('fr', '🇫🇷', 'Français'),
        _buildItem('en', '🇬🇧', 'English'),
        _buildItem('ar', '🇩🇿', 'العربية'),
      ],
    );
  }

  PopupMenuItem<String> _buildItem(String code, String flag, String label) {
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  String _flag(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'ar':
        return '🇩🇿';
      default:
        return '🇫🇷';
    }
  }

  String _label(String code) {
    switch (code) {
      case 'en':
        return 'EN';
      case 'ar':
        return 'عر';
      default:
        return 'FR';
    }
  }
}
