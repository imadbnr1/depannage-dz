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
    final current = _LanguageOption.fromCode(ctrl.locale.languageCode);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showLabel = constraints.maxWidth >= 132;
        final maxWidth = compact ? 144.0 : 168.0;

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: showLabel ? 118 : 52,
            maxWidth: maxWidth,
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Language',
            initialValue: ctrl.locale.languageCode,
            onSelected: ctrl.setLanguage,
            offset: const Offset(0, 10),
            elevation: 10,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFEADFCC)),
            ),
            itemBuilder: (context) => _LanguageOption.values.map((option) {
              final selected = option.code == ctrl.locale.languageCode;
              return PopupMenuItem<String>(
                value: option.code,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _LanguageMenuItem(
                  option: option,
                  selected: selected,
                ),
              );
            }).toList(),
            child: Container(
              height: compact ? 40 : 44,
              padding: EdgeInsets.symmetric(
                horizontal: showLabel ? 14 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.58),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F0F172A),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    current.flag,
                    style: TextStyle(fontSize: compact ? 18 : 20),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        current.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: compact ? 16 : 18,
                    color: const Color(0xFF0F172A),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LanguageMenuItem extends StatelessWidget {
  const _LanguageMenuItem({
    required this.option,
    required this.selected,
  });

  final _LanguageOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF4DE) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: selected
            ? Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.flag,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.flag,
    required this.label,
  });

  final String code;
  final String flag;
  final String label;

  static const values = [
    _LanguageOption(
      code: 'ar',
      flag: '\u{1F1E9}\u{1F1FF}',
      label: '\u0627\u0644\u0639\u0631\u0628\u064A\u0629',
    ),
    _LanguageOption(
      code: 'en',
      flag: '\u{1F1EC}\u{1F1E7}',
      label: 'English',
    ),
    _LanguageOption(
      code: 'fr',
      flag: '\u{1F1EB}\u{1F1F7}',
      label: 'Fran\u00E7ais',
    ),
  ];

  static _LanguageOption fromCode(String code) {
    return values.firstWhere(
      (option) => option.code == code,
      orElse: () => values.last,
    );
  }
}
