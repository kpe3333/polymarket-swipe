import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/watchlist.dart';
import '../models/market.dart';
import '../utils/category_colors.dart';
import '../utils/haptic.dart';
import '../widgets/bet_dialog.dart';
import 'market_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _store = WatchlistStore();

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
  }

  void _onChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _openBet(Market m) async {
    Haptic.medium();
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final result = await showBetDialog(context, m);
    if (result != null && mounted) {
      await _store.remove(m.id); // remove from watchlist after betting
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bet placed: \$${result.amount.toStringAsFixed(2)} on ${result.outcome}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF00D09E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final markets = _store.markets;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(markets.length),
            Expanded(
              child: markets.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: markets.length,
                      itemBuilder: (_, i) => _WatchCard(
                        market: markets[i],
                        onTap: () {
                          Haptic.selection();
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => MarketDetailScreen(market: markets[i])));
                        },
                        onBet: () => _openBet(markets[i]),
                        onRemove: () {
                          Haptic.light();
                          _store.remove(markets[i].id);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('WATCHLIST',
              style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: const Color(0xFF00D09E), letterSpacing: 2,
              )),
          const Spacer(),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D09E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$count saved',
                  style: GoogleFonts.inter(color: const Color(0xFF00D09E), fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          Text('No saved markets',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Swipe up or tap ★ on a card to save it',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

class _WatchCard extends StatelessWidget {
  final Market market;
  final VoidCallback onTap;
  final VoidCallback onBet;
  final VoidCallback onRemove;

  const _WatchCard({required this.market, required this.onTap, required this.onBet, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(market.category);
    return Dismissible(
      key: ValueKey(market.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D6D).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF4D6D)),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: style.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              if (market.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(market.image!, width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _catIcon(style.primary)),
                )
              else
                _catIcon(style.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (market.category != null)
                      Text(market.category!.toUpperCase(),
                          style: GoogleFonts.inter(color: style.primary, fontSize: 10,
                              fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 2),
                    Text(market.question,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('${market.yesPct}% YES',
                          style: GoogleFonts.inter(color: const Color(0xFF00D09E), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('${market.noPct}% NO',
                          style: GoogleFonts.inter(color: const Color(0xFFFF4D6D), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('Vol ${market.volumeFormatted}',
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  GestureDetector(
                    onTap: onBet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: style.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: style.primary.withOpacity(0.4)),
                      ),
                      child: Text('BET',
                          style: GoogleFonts.inter(color: style.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onRemove,
                    child: Icon(Icons.bookmark_remove_outlined, color: Colors.white24, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _catIcon(Color color) => Container(
    width: 56, height: 56,
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
    child: Center(child: Icon(Icons.bookmark_rounded, color: color, size: 24)),
  );
}
