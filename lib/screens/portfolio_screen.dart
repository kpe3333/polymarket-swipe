import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bet.dart';
import '../utils/category_colors.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
  final _store = BetStore();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _store.load().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSummaryCards(),
            _buildTabs(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text('PORTFOLIO',
              style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: const Color(0xFF00D09E), letterSpacing: 2,
              )),
          const Spacer(),
          // Demo button to simulate resolutions
          TextButton(
            onPressed: () async {
              await _store.simulateResolution();
              setState(() {});
            },
            child: Text('Simulate', style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final pnl = _store.realizedPnL;
    final pnlColor = pnl >= 0 ? const Color(0xFF00D09E) : const Color(0xFFFF4D6D);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          // Main PnL card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: pnl >= 0
                    ? [const Color(0xFF003D30), const Color(0xFF001A14)]
                    : [const Color(0xFF3D0010), const Color(0xFF1A0008)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: pnlColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Realized P&L',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 36, fontWeight: FontWeight.w900, color: pnlColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(label: 'Win Rate',
                        value: '${(_store.winRate * 100).toStringAsFixed(0)}%',
                        color: const Color(0xFF00D09E)),
                    const SizedBox(width: 20),
                    _MiniStat(label: 'Won', value: '${_store.wins}', color: const Color(0xFF00D09E)),
                    const SizedBox(width: 20),
                    _MiniStat(label: 'Lost', value: '${_store.losses}', color: const Color(0xFFFF4D6D)),
                    const SizedBox(width: 20),
                    _MiniStat(label: 'Open', value: '${_store.open.length}', color: Colors.white54),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Open positions summary
          if (_store.open.isNotEmpty)
            Row(
              children: [
                Expanded(child: _SummaryChip(
                  label: 'Invested',
                  value: '\$${_store.totalInvested.toStringAsFixed(2)}',
                  color: Colors.white54,
                )),
                const SizedBox(width: 10),
                Expanded(child: _SummaryChip(
                  label: 'Potential Return',
                  value: '\$${_store.totalPotential.toStringAsFixed(2)}',
                  color: const Color(0xFF00D09E),
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabs,
          indicator: BoxDecoration(
            color: const Color(0xFF00D09E).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00D09E).withOpacity(0.5)),
          ),
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF00D09E),
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Open (${_store.open.length})'),
            Tab(text: 'History (${_store.resolved.length})'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabs,
      children: [
        _buildBetList(_store.open, empty: 'No open bets yet\nSwipe right to place a bet!'),
        _buildBetList(_store.resolved, empty: 'No resolved bets yet'),
      ],
    );
  }

  Widget _buildBetList(List<Bet> bets, {required String empty}) {
    if (bets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(empty,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 15, height: 1.5)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: bets.length,
      itemBuilder: (_, i) => _BetCard(bet: bets[i]),
    );
  }
}

class _BetCard extends StatelessWidget {
  final Bet bet;
  const _BetCard({required this.bet});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(bet.category);
    final isOpen = bet.status == BetStatus.open;
    final isWon = bet.status == BetStatus.won;
    final statusColor = isOpen
        ? Colors.white38
        : isWon ? const Color(0xFF00D09E) : const Color(0xFFFF4D6D);
    final statusLabel = isOpen ? 'OPEN' : isWon ? 'WON' : 'LOST';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: style.primary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image or category icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: bet.image != null
                ? Image.network(bet.image!, width: 52, height: 52, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _catIcon(style.primary, bet.category))
                : _catIcon(style.primary, bet.category),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bet.question,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: style.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(bet.outcome,
                          style: GoogleFonts.inter(color: style.primary,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text('@ ${(bet.price * 100).toStringAsFixed(0)}¢',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Bet', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      Text('\$${bet.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(color: Colors.white70,
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Text('To win', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      Text('\$${bet.potentialReturn.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(color: const Color(0xFF00D09E),
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('P&L', style: GoogleFonts.inter(color: Colors.white24, fontSize: 10)),
                      Text(
                        isOpen ? '—'
                            : '${bet.pnl >= 0 ? '+' : ''}\$${bet.pnl.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: isOpen ? Colors.white38 : statusColor,
                          fontSize: 14, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.4)),
            ),
            child: Text(statusLabel,
                style: GoogleFonts.inter(color: statusColor,
                    fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _catIcon(Color color, String? cat) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(_emoji(cat), style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  String _emoji(String? cat) {
    switch (cat) {
      case 'Politics': return '🗳️';
      case 'Crypto': return '₿';
      case 'Sports': return '🏆';
      case 'Finance': return '📈';
      case 'Science': return '🔬';
      case 'Entertainment': return '🎬';
      default: return '🌍';
    }
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
    ]);
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}
