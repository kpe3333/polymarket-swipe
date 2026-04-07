import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../services/polymarket_service.dart';
import '../widgets/market_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _service = PolymarketService();
  final _swiperController = AppinioSwiperController();

  List<Market> _markets = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  int _bets = 0;
  int _skips = 0;

  @override
  void initState() {
    super.initState();
    _loadMarkets();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final markets = await _service.fetchMarkets();
      setState(() {
        _markets = markets;
        _loading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onSwipe(int prevIndex, int? currentIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      if (activity.direction == AxisDirection.right) {
        setState(() => _bets++);
        _showFeedback('BET placed!', const Color(0xFF00D09E));
      } else if (activity.direction == AxisDirection.left) {
        setState(() => _skips++);
      }
    }
    if (currentIndex != null) {
      setState(() => _currentIndex = currentIndex);
    }
  }

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildBody()),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Text(
            'POLYMARKET',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00D09E),
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          _StatBadge(label: '🎯', value: _bets.toString(), color: const Color(0xFF00D09E)),
          const SizedBox(width: 8),
          _StatBadge(label: '⏭', value: _skips.toString(), color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00D09E)),
            const SizedBox(height: 16),
            Text(
              'Loading markets...',
              style: GoogleFonts.inter(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
              const SizedBox(height: 16),
              Text(
                'Could not load markets',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMarkets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D09E),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    if (_markets.isEmpty) {
      return Center(
        child: Text('No markets available', style: GoogleFonts.inter(color: Colors.white38)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppinioSwiper(
        controller: _swiperController,
        cardCount: _markets.length,
        onSwipeEnd: _onSwipe,
        onEnd: () {
          setState(() {});
          _showFeedback('All markets reviewed!', Colors.white24);
        },
        cardBuilder: (context, index) {
          return MarketCard(market: _markets[index]);
        },
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_loading || _error != null || _markets.isEmpty) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // SKIP button
          _ActionButton(
            onTap: () => _swiperController.swipeLeft(),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF4D6D),
            label: 'SKIP',
          ),
          const SizedBox(width: 16),
          // BET button
          _ActionButton(
            onTap: () => _swiperController.swipeRight(),
            icon: Icons.bolt_rounded,
            color: const Color(0xFF00D09E),
            label: 'BET',
            large: true,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color color;
  final String label;
  final bool large;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.label,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 72.0 : 60.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: large
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)]
                  : null,
            ),
            child: Icon(icon, color: color, size: large ? 32 : 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
