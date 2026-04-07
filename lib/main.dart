import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_settings.dart';
import 'models/bet.dart';
import 'services/translation_service.dart';
import 'screens/feed_screen.dart';
import 'screens/search_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/account_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().load();
  await BetStore().load();
  final ts = TranslationService();
  await ts.load();
  if (ts.mode == LangMode.byIp) await ts.detectByIp();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const PolymarketApp());
}

class PolymarketApp extends StatelessWidget {
  const PolymarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings(),
      builder: (_, __) {
        final dark = AppSettings().darkMode;
        return MaterialApp(
          title: 'PolySwipe',
          debugShowCheckedModeBanner: false,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF0A0A14),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D09E),
              secondary: Color(0xFFFF4D6D),
            ),
          ),
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF2F4F7),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF00A87A),
              secondary: Color(0xFFE5334A),
            ),
          ),
          home: const _AppEntry(),
        );
      },
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _onboardingDone;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final p = await SharedPreferences.getInstance();
    setState(() => _onboardingDone = p.getBool('onboarding_done') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingDone == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A14),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
      );
    }
    if (!_onboardingDone!) {
      return OnboardingScreen(onDone: () => setState(() => _onboardingDone = true));
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  final _screens = const [
    FeedScreen(),
    SearchScreen(),
    PortfolioScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.layers_rounded, label: 'Feed', index: 0, current: _tab, onTap: _setTab),
              _NavItem(icon: Icons.search_rounded, label: 'Search', index: 1, current: _tab, onTap: _setTab),
              _NavItem(icon: Icons.bar_chart_rounded, label: 'Portfolio', index: 2, current: _tab, onTap: _setTab),
              _NavItem(icon: Icons.person_rounded, label: 'Account', index: 3, current: _tab, onTap: _setTab),
            ],
          ),
        ),
      ),
    );
  }

  void _setTab(int i) => setState(() => _tab = i);
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.index, required this.current, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sel = index == current;
    final color = sel ? const Color(0xFF00D09E) : Colors.white24;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(
              color: color, fontSize: 10,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
            )),
            if (sel)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4, height: 4,
                decoration: const BoxDecoration(color: Color(0xFF00D09E), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
