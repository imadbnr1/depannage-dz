import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../widgets/language_selector.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onFinish,
  });

  final VoidCallback onFinish;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  static const _itemCount = 3;
  int _index = 0;

  List<_OnboardingItem> _items(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return [
      _OnboardingItem(
        icon: Icons.location_on_outlined,
        title: strings.t('onboardingTitle1'),
        text: strings.t('onboardingText1'),
        hint: strings.t('onboardingHint1'),
        colors: const [Color(0xFF2563EB), Color(0xFF38BDF8)],
      ),
      _OnboardingItem(
        icon: Icons.route_outlined,
        title: strings.t('onboardingTitle2'),
        text: strings.t('onboardingText2'),
        hint: strings.t('onboardingHint2'),
        colors: const [Color(0xFF059669), Color(0xFF34D399)],
      ),
      _OnboardingItem(
        icon: Icons.verified_outlined,
        title: strings.t('onboardingTitle3'),
        text: strings.t('onboardingText3'),
        hint: strings.t('onboardingHint3'),
        colors: const [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      ),
    ];
  }

  void _next() {
    if (_index == _itemCount - 1) {
      widget.onFinish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = _items(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFCF7),
              Color(0xFFF5EEDF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFEADFCC)),
                      ),
                      child: Text(
                        '${_index + 1}/$_itemCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const LanguageSelector(compact: true),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onFinish,
                      child: Text(strings.t('skip')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: items.length,
                  onPageChanged: (value) {
                    setState(() => _index = value);
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 640 ||
                            constraints.maxWidth < 360;
                        final heroSize = compact ? 172.0 : 230.0;
                        final iconSize = compact ? 64.0 : 86.0;
                        final titleSize = compact ? 22.0 : 30.0;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 48,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 280),
                                  width: heroSize,
                                  height: heroSize,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: item.colors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(44),
                                    boxShadow: [
                                      BoxShadow(
                                        color: item.colors.first.withValues(
                                          alpha: 0.26,
                                        ),
                                        blurRadius: 30,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.16,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Icon(
                                          item.icon,
                                          color: Colors.white,
                                          size: iconSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 24 : 34),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  item.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF6B7280),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.74),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: const Color(0xFFEADFCC),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: item.colors.first.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.colors.first,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          index == 0
                                              ? items[0].hint
                                              : index == 1
                                                  ? items[1].hint
                                                  : items[2].hint,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _itemCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _next,
                    icon: Icon(
                      _index == _itemCount - 1
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      _index == _itemCount - 1
                          ? strings.t('enterApp')
                          : strings.t('next'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.text,
    required this.hint,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String text;
  final String hint;
  final List<Color> colors;
}
