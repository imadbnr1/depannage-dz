import 'package:flutter/material.dart';

class ModernBottomNavItem {
  const ModernBottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.semanticLabel,
    this.badgeCount,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String semanticLabel;
  final int? badgeCount;
}

class ModernBottomNavBar extends StatelessWidget {
  const ModernBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<ModernBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    const navy = Color(0xFF0F172A);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border(
          top:
              BorderSide(color: const Color(0xFFE2D6C2).withValues(alpha: 0.7)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(12, 6, 12, bottomInset > 0 ? 6 : 8),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minWidth = items.length * 56.0;
                final scrollable = minWidth > constraints.maxWidth;
                final content = Row(
                  mainAxisSize:
                      scrollable ? MainAxisSize.min : MainAxisSize.max,
                  mainAxisAlignment: scrollable
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    for (var index = 0; index < items.length; index++)
                      _ModernBottomNavButton(
                        item: items[index],
                        selected: index == selectedIndex,
                        primary: primary,
                        navy: navy,
                        onTap: () => onTap(index),
                      ),
                  ],
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: scrollable
                      ? SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: content,
                        )
                      : content,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernBottomNavButton extends StatelessWidget {
  const _ModernBottomNavButton({
    required this.item,
    required this.selected,
    required this.primary,
    required this.navy,
    required this.onTap,
  });

  final ModernBottomNavItem item;
  final bool selected;
  final Color primary;
  final Color navy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badgeCount = item.badgeCount ?? 0;

    return Tooltip(
      message: item.semanticLabel,
      child: Semantics(
        label: item.semanticLabel,
        button: true,
        selected: selected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 48,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      scale: selected ? 1.08 : 1,
                      child: Icon(
                        selected ? item.selectedIcon : item.icon,
                        color: selected ? navy : const Color(0xFF64748B),
                        size: selected ? 25 : 23,
                      ),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: 7,
                        top: 7,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badgeCount > 99 ? '99+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
