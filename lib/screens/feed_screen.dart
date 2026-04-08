import 'dart:async';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/haptic.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../models/app_settings.dart';
import '../models/watchlist.dart';
import '../models/viewed_markets.dart';
import '../services/polymarket_service.dart';
import '../widgets/market_card.dart';
import '../widgets/bet_dialog.dart';
import 'market_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _service = PolymarketService();
  final _swiperController = AppinioSwiperController();
  final _settings = AppSettings();

  final _watchlist = WatchlistStore();
  final _viewed = ViewedStore();

  List<Market> _markets = [];
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  int _bets = 0;
  int _skips = 0;
  int _saved = 0;
  bool _loadingMore = false;
  Market? _lastSkipped;
  double _swipeProgress = 0.0;
  Key _swiperKey = UniqueKey();
  Set<String> _lastCategories = {};
  Timer? _refreshTimer;

  List<Market> get _filtered {
    final viewed = _viewed;
    var list = _markets.where((m) => !viewed.isViewed(m.id)).toList();
    if (_settings.selectedCategories.isNotEmpty) {
      list = list.where((m) => _settings.selectedCategories.contains(m.category)).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _lastCategories = Set.from(_settings.selectedCategories);
    _loadMarkets();
    _settings.addListener(_onSettingsChanged);
    _watchlist.addListener(_rebuild);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _autoRefreshPrices());
  }

  void _rebuild() { if (mounted) setState(() {}); }

  void _onSettingsChanged() {
    if (!setEquals(_settings.selectedCategories, _lastCategories)) {
      _lastCategories = Set.from(_settings.selectedCategories);
      setState(() { _currentIndex = 0; _swiperKey = UniqueKey(); });
    }
  }

  Future<void> _autoRefreshPrices() async {
    if (!mounted || _markets.isEmpty) return;
    try {
      final fresh = await _service.fetchMarkets(limit: 100);
      if (!mounted) return;
      final Map<String, Market> byId = { for (final m in fresh) m.id: m };
      setState(() {
        _markets = _markets.map((m) => byId[m.id] ?? m).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _settings.removeListener(_onSettingsChanged);
    _watchlist.removeListener(_rebuild);
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkets({bool more = false}) async {
    if (!more) setState(() { _loading = true; _error = null; });
    else setState(() => _loadingMore = true);
    try {
      final markets = await _service.fetchMarkets(limit: 100);
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
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  void _onSwipe(int prevIndex, int? currentIndex, SwiperActivity activity) {
    final cards = _filtered;
    if (activity is Swipe) {
      final market = prevIndex < cards.length ? cards[prevIndex] : null;
      if (market != null) _viewed.markViewed(market.id);

      if (activity.direction == AxisDirection.right) {
        Haptic.swipe();
        setState(() { _bets++; _lastSkipped = null; });
        if (market != null) _openBetDialog(market);
      } else if (activity.direction == AxisDirection.left) {
        Haptic.swipe();
        setState(() { _skips++; _lastSkipped = market; });
      } else if (activity.direction == AxisDirection.up) {
        if (market != null) _saveToWatchlist(market);
      }
    }
    if (currentIndex != null) {
      setState(() => _currentIndex = currentIndex);
      if (_markets.length - currentIndex <= 5 && !_loadingMore) {
        _loadMarkets(more: true);
      }
    }
  }

  Future<void> _openBetDialog(Market market) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final result = await showBetDialog(context, market);
    if (result != null && mounted) {
      Haptic.heavy();
      _showFeedback(
        '🎯 Bet placed: \$${result.amount.toStringAsFixed(0)} on ${result.outcome}',
        const Color(0xFF00D09E),
      );
    }
  }

  void _openDetail(Market market) {
    Haptic.selection();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MarketDetailScreen(market: market)),
    );
  }

  void _undoLastSkip() {
    try {
      _swiperController.unswipe();
      Haptic.swipe();
      setState(() { _skips = (_skips - 1).clamp(0, 9999); _lastSkipped = null; });
    } catch (_) {}
  }

  void _saveToWatchlist(Market market) {
    Haptic.swipe();
    _watchlist.toggle(market);
    final isNowSaved = _watchlist.isWatched(market.id);
    setState(() { if (isNowSaved) _saved++; });
    _showFeedback(
      isNowSaved ? '🔖 Saved to Watchlist' : '🗑 Removed from Watchlist',
      isNowSaved ? const Color(0xFF00D09E) : Colors.white24,
    );
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
            ...[
              'Undo skipped cards',
              'Advanced filters',
              'Portfolio analytics',
              'Price alerts',
            ].map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 16),
                const SizedBox(width: 8),
                Text(f, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              ]),
            )),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      duration: const Duration(milliseconds: 1200),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
    ));
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
    final remaining = _filtered.isEmpty ? 0 : (_filtered.length - _currentIndex).clamp(0, _filtered.length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Text(
            'POLYSWIPED',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00D09E),
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          if (_loadingMore)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00D09E)),
              ),
            ),
          if (!_loading && _markets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$remaining left',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
              ),
            ),
          const SizedBox(width: 8),
          _StatBadge(label: '🎯', value: _bets.toString(), color: const Color(0xFF00D09E)),
          const SizedBox(width: 6),
          _StatBadge(label: '🔖', value: _saved.toString(), color: const Color(0xFFFFD700)),
          const SizedBox(width: 6),
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

    final cards = _filtered;
    if (cards.isEmpty) {
      return _EmptyState(onRefresh: _loadMarkets);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Listener(
        onPointerMove: (e) {
          final screenWidth = MediaQuery.of(context).size.width;
          final delta = e.delta.dx / screenWidth * 2.5;
          final next = (_swipeProgress + delta).clamp(-1.0, 1.0);
          if ((next - _swipeProgress).abs() > 0.01) {
            setState(() => _swipeProgress = next);
          }
        },
        onPointerUp: (_) => setState(() => _swipeProgress = 0.0),
        onPointerCancel: (_) => setState(() => _swipeProgress = 0.0),
        child: AppinioSwiper(
          key: _swiperKey,
          controller: _swiperController,
          cardCount: cards.length,
          onSwipeEnd: _onSwipe,
          onEnd: () => _loadMarkets(),
          cardBuilder: (context, index) => MarketCard(
            key: ValueKey(cards[index].id),
            market: cards[index],
            swipeProgress: index == _currentIndex ? _swipeProgress : 0.0,
            onTap: () => _openDetail(cards[index]),
          ),
        ),
      ),
    );
  }

  bool get _currentSaved {
    final cards = _filtered;
    if (_currentIndex >= cards.length) return false;
    return _watchlist.isWatched(cards[_currentIndex].id);
  }

  Widget _buildBottomButtons() {
    if (_loading || _error != null || _markets.isEmpty) return const SizedBox(height: 20);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            onTap: () { Haptic.swipe(); _swiperController.swipeLeft(); },
            icon: Icons.close_rounded,
            color: const Color(0xFFFF4D6D),
            label: 'SKIP',
          ),
          _ActionButton(
            onTap: () {
              if (_lastSkipped != null) _undoLastSkip();
              else _showPremiumDialog();
            },
            icon: Icons.undo_rounded,
            color: const Color(0xFFFFD700),
            label: 'UNDO',
            badge: _lastSkipped == null ? '★' : null,
          ),
          _ActionButton(
            onTap: () {
              final cards = _filtered;
              if (_currentIndex < cards.length) _saveToWatchlist(cards[_currentIndex]);
            },
            icon: _currentSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: const Color(0xFFB57BFF),
            label: 'SAVE',
          ),
          _ActionButton(
            onTap: () { Haptic.swipe(); _swiperController.swipeRight(); },
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

class _EmptyState extends StatefulWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scale = Tween(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: const Text('🎯', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 20),
          Text(
            "You've seen it all!",
            style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Load fresh markets',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Refresh', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D09E),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
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
  final String? badge;

  const _ActionButton({
    required this.onTap, required this.icon,
    required this.color, required this.label,
    this.large = false, this.badge,
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
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                  boxShadow: large ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, spreadRadius: 2)] : null,
                ),
                child: Icon(icon, color: color, size: large ? 30 : 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4, right: -4,
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
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
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
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$label $value', style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
