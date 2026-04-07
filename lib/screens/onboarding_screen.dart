import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      emoji: '🎯',
      title: 'Predict the Future',
      subtitle:
          'Browse real prediction markets from Polymarket — politics, crypto, sports, and more.',
      gradient: [Color(0xFF003D30), Color(0xFF0A0A14)],
      accent: Color(0xFF00D09E),
    ),
    _OnboardPage(
      emoji: '👆',
      title: 'Swipe to Bet',
      subtitle:
          'Swipe right to place a bet. Swipe left to skip. Tap a card for full details.',
      gradient: [Color(0xFF1A0040), Color(0xFF0A0A14)],
      accent: Color(0xFFB57BFF),
      showGesture: true,
    ),
    _OnboardPage(
      emoji: '📊',
      title: 'Track Your Portfolio',
      subtitle:
          'See your open positions, P&L, and win rate in the Portfolio tab.',
      gradient: [Color(0xFF2D1A00), Color(0xFF0A0A14)],
      accent: Color(0xFFFFD700),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => _PageView(page: _pages[i]),
          ),
          // Dots + buttons
          Positioned(
            left: 0, right: 0, bottom: 48,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final sel = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: sel ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: sel ? _pages[_page].accent : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: () => _controller.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut),
                          child: Text('Back',
                              style: GoogleFonts.inter(color: Colors.white38, fontSize: 15)),
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (_page < _pages.length - 1) {
                            _controller.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut);
                          } else {
                            _finish();
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            color: _pages[_page].accent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_page].accent.withOpacity(0.4),
                                blurRadius: 16, spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            _page < _pages.length - 1 ? 'Next →' : 'Start Betting!',
                            style: GoogleFonts.inter(
                              color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Skip
          Positioned(
            top: 52, right: 20,
            child: TextButton(
              onPressed: _finish,
              child: Text('Skip', style: GoogleFonts.inter(color: Colors.white24, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accent;
  final bool showGesture;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accent,
    this.showGesture = false,
  });
}

class _PageView extends StatefulWidget {
  final _OnboardPage page;
  const _PageView({required this.page});

  @override
  State<_PageView> createState() => _PageViewState();
}

class _PageViewState extends State<_PageView> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _float;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _float = Tween(begin: -10.0, end: 10.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _slide = Tween(begin: widget.page.showGesture ? -60.0 : 0.0, end: widget.page.showGesture ? 60.0 : 0.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.page.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated emoji / illustration
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => Transform.translate(
                  offset: widget.page.showGesture
                      ? Offset(_slide.value, _float.value)
                      : Offset(0, _float.value),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140, height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.page.accent.withOpacity(0.12),
                          border: Border.all(color: widget.page.accent.withOpacity(0.3), width: 2),
                        ),
                      ),
                      Text(widget.page.emoji, style: const TextStyle(fontSize: 64)),
                      if (widget.page.showGesture) ...[
                        Positioned(
                          right: -10,
                          child: Icon(Icons.arrow_forward_rounded,
                              color: const Color(0xFF00D09E), size: 28),
                        ),
                        Positioned(
                          left: -10,
                          child: Icon(Icons.arrow_back_rounded,
                              color: const Color(0xFFFF4D6D), size: 28),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(widget.page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.2,
                  )),
              const SizedBox(height: 16),
              Text(widget.page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 16, height: 1.6,
                  )),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
