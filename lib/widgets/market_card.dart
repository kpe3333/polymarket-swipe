import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';

class MarketCard extends StatelessWidget {
  final Market market;
  final double swipeProgress;

  const MarketCard({
    super.key,
    required this.market,
    this.swipeProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 14),
                      _buildQuestion(),
                      if (market.description != null && market.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildDescription(),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Chart
                SizedBox(
                  height: 80,
                  child: _MiniChart(
                    yesPrice: market.yesPrice,
                    color: const Color(0xFF00D09E),
                  ),
                ),

                // Odds + stats
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    children: [
                      _buildOddsBar(),
                      const SizedBox(height: 14),
                      _buildStats(),
                    ],
                  ),
                ),
              ],
            ),

            // BET label
            if (swipeProgress > 0.05)
              Positioned(
                top: 32,
                left: 20,
                child: _SwipeLabel(
                  label: 'BET',
                  color: const Color(0xFF00D09E),
                  opacity: swipeProgress.clamp(0.0, 1.0),
                ),
              ),

            // SKIP label
            if (swipeProgress < -0.05)
              Positioned(
                top: 32,
                right: 20,
                child: _SwipeLabel(
                  label: 'SKIP',
                  color: const Color(0xFFFF4D6D),
                  opacity: (-swipeProgress).clamp(0.0, 1.0),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460).withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00D09E).withOpacity(0.3)),
          ),
          child: Text(
            market.category?.toUpperCase() ?? 'MARKET',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00D09E),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Spacer(),
        if (market.endDate != null)
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 12, color: Colors.white30),
              const SizedBox(width: 4),
              Text(
                _formatDeadline(market.endDate!),
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Text(
      market.question,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      ),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Text(
      market.description!,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: Colors.white38,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOddsBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _OddsLabel(
              label: market.outcomes.isNotEmpty ? market.outcomes[0] : 'YES',
              pct: market.yesPct,
              color: const Color(0xFF00D09E),
            ),
            _OddsLabel(
              label: market.outcomes.length > 1 ? market.outcomes[1] : 'NO',
              pct: market.noPct,
              color: const Color(0xFFFF4D6D),
              align: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: market.yesPct,
                  child: Container(color: const Color(0xFF00D09E)),
                ),
                Expanded(
                  flex: market.noPct,
                  child: Container(color: const Color(0xFFFF4D6D)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatChip(icon: Icons.bar_chart_rounded, label: 'Vol ${market.volumeFormatted}'),
        const SizedBox(width: 8),
        _StatChip(icon: Icons.people_outline_rounded, label: 'Polymarket'),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF00D09E).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00D09E).withOpacity(0.4)),
          ),
          child: Text(
            '${market.yesPct}% YES',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF00D09E),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDeadline(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return 'Soon';
  }
}

/// Mini sparkline chart — simulates price movement towards current YES price
class _MiniChart extends StatelessWidget {
  final double yesPrice;
  final Color color;

  const _MiniChart({required this.yesPrice, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = _generateSpots(yesPrice);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.25),
                    color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          minY: 0,
          maxY: 1,
        ),
      ),
    );
  }

  List<FlSpot> _generateSpots(double endPrice) {
    // Generate a plausible-looking price history ending at current price
    final rng = Random(endPrice.hashCode);
    final points = 20;
    final spots = <FlSpot>[];
    double price = 0.5 + (rng.nextDouble() - 0.5) * 0.3;

    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      // Gradually converge towards endPrice
      final target = price + (endPrice - price) * (t * t);
      final noise = (rng.nextDouble() - 0.5) * 0.06 * (1 - t);
      price = (target + noise).clamp(0.02, 0.98);
      spots.add(FlSpot(i.toDouble(), price));
    }
    // Force last point to actual price
    spots[points - 1] = FlSpot((points - 1).toDouble(), endPrice.clamp(0.02, 0.98));
    return spots;
  }
}

class _OddsLabel extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  final TextAlign align;

  const _OddsLabel({
    required this.label,
    required this.pct,
    required this.color,
    this.align = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '$pct%',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white38),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _SwipeLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;

  const _SwipeLabel({required this.label, required this.color, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
