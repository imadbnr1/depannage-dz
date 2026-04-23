import 'package:flutter/material.dart';

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
  int _index = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      icon: Icons.location_on_outlined,
      title: 'Demandez une assistance rapidement',
      text:
          'Choisissez votre service, ajoutez votre destination et obtenez une estimation claire.',
      colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
    ),
    _OnboardingItem(
      icon: Icons.route_outlined,
      title: 'Suivez la mission en direct',
      text:
          'Consultez la progression du provider, son arrivee et l etat de votre mission.',
      colors: [Color(0xFF059669), Color(0xFF34D399)],
    ),
    _OnboardingItem(
      icon: Icons.verified_outlined,
      title: 'Une plateforme complete',
      text:
          'Customer, provider et admin travaillent ensemble dans une experience moderne et professionnelle.',
      colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    ),
  ];

  void _next() {
    if (_index == _items.length - 1) {
      widget.onFinish();
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: widget.onFinish,
                  child: const Text('Passer'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _items.length,
                onPageChanged: (value) {
                  setState(() => _index = value);
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 640 ||
                          constraints.maxWidth < 360;
                      final heroSize = compact ? 170.0 : 230.0;
                      final iconSize = compact ? 64.0 : 86.0;
                      final titleSize = compact ? 22.0 : 28.0;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: heroSize,
                                height: heroSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: item.colors,
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: item.colors.first.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 24,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item.icon,
                                  color: Colors.white,
                                  size: iconSize,
                                ),
                              ),
                              SizedBox(height: compact ? 24 : 36),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                item.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black54,
                                  height: 1.45,
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
                _items.length,
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
                    _index == _items.length - 1
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    _index == _items.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                  ),
                ),
              ),
            ),
          ],
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
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String text;
  final List<Color> colors;
}
