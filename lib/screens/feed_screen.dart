import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../models/app_settings.dart';
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
  final _settings = AppSettings();

  List<Market> _markets = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  int _bets = 0;
  int _skips = 0;
  bool _loadingMore = false;

  // For premium undo
  Market? _lastSkipped;

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

  Future<void> _loadMarkets({bool more = false}) async {
    if (!more) setState(() { _loading = true; _error = null; });
    else setState(() => _loadingMore = true);

    try {
      final markets = await _service.fetchMarkets(limit: 30);
      setState(() {
        if (more) {
          _markets.addAll(markets);
        } else {
          _markets = markets;
          _currentIndex = 0;
        }
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSwipe(int prevIndex, int? currentIndex, SwiperActivity activity) {
    if (activity is Swipe) {
      if (activity.direction == AxisDirection.right) {
        setState(() => _bets++);
        _showFeedback('BET placed! \$${_settings.defaultBet.toStringAsFixed(0)}', const Color(0xFF00D09E));
        _lastSkipped = null;
      } else if (activity.direction == AxisDirection.left) {
        _lastSkipped = _markets[prevIndex];
        setState(() => _skips++);
      }
    }
    if (currentIndex != null) {
      setState(() => _currentIndex = currentIndex);
      // Load more when 5 cards remaining
      if (_markets.length - currentIndex <= 5 && !_loadingMore) {
        _loadMarkets(more: true);
      }
    }
  }

  void _onEnd() {
    _loadMarkets();
    _showFeedback('Loading more markets...', Colors.white24);
  }

  void _undoLastSkip() {
    if (_lastSkipped == null) return;
    // Premium: rewind one card
    try {
      _swiperController.unswipe();
      setState(() {
        _skips = (_skips - 1).clamp(0, 9999);
        _lastSkipped = null;
      });
    } catch (_) {}
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24),
            const SizedBox(width: 8),
            Text('Premium', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Unlock Premium to:', style: GoogleFonts.inter(color: Colors.white54)),
            const SizedBox(height: 12),
            _PremiumFeature('Undo skipped cards'),
            _PremiumFeature('Advanced filters'),
            _PremiumFeature('Portfolio analytics'),
            _PremiumFeature('Price alerts'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Upgrade', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
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
          if (_loadingMore)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D09E)),
            ),
          const SizedBox(width: 10),
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
            Text('Loading markets...', style: GoogleFonts.inter(color: Colors.white38)),
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
              Text('Could not load markets', style: GoogleFonts.inter(color: Colors.white54, fontSize: 16)),
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
      return Center(child: Text('No markets available', style: GoogleFonts.inter(color: Colors.white38)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: AppinioSwiper(
        controller: _swiperController,
        cardCount: _markets.length,
        onSwipeEnd: _onSwipe,
        onEnd: _onEnd,
        cardBuilder: (context, index) => MarketCard(market: _markets[index]),
      ),
    );
  }

  Widget _buildBottomButtons() {
    if (_loading || _error != null || _markets.isEmpty) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // SKIP
          _ActionButton(
            onTap: () => _swiperController.swipeLeft(),
            icon: Icons.close_rounded,
            color: const Color(0xFFFF4D6D),
            label: 'SKIP',
          ),

          // UNDO (premium)
          _ActionButton(
            onTap: () {
              if (_lastSkipped != null) {
                _undoLastSkip();
              } else {
                _showPremiumDialog();
              }
            },
            icon: Icons.undo_rounded,
            color: const Color(0xFFFFD700),
            label: 'UNDO',
            badge: _lastSkipped == null ? '★' : null,
          ),

          // BET
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

class _PremiumFeature extends StatelessWidget {
  final String text;
  const _PremiumFeature(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
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
  final String? badge;

  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.color,
    required this.label,
    this.large = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 68.0 : 56.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
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
                child: Icon(icon, color: color, size: large ? 30 : 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0A0A14), width: 1.5),
                    ),
                    child: Text(badge!, style: const TextStyle(fontSize: 8, color: Colors.black)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.2,
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
        style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
