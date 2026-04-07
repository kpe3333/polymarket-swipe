import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../utils/category_colors.dart';
import '../widgets/bet_dialog.dart';

class MarketDetailScreen extends StatelessWidget {
  final Market market;

  const MarketDetailScreen({super.key, required this.market});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(market.category);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: CustomScrollView(
        slivers: [
          // App bar with image or gradient
          SliverAppBar(
            expandedHeight: market.image != null ? 220 : 140,
            pinned: true,
            backgroundColor: Color(style.bg.value),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (market.image != null && market.image!.isNotEmpty)
                    Image.network(market.image!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gradientBg(style.gradient))
                  else
                    _gradientBg(style.gradient),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, const Color(0xFF0A0A14)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: style.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: style.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      (market.category ?? 'MARKET').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: style.primary, letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Question
                  Text(
                    market.question,
                    style: GoogleFonts.inter(
                      fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.white, height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Odds row
                  Row(
                    children: [
                      Expanded(child: _BigOdds(label: market.outcomes.isNotEmpty ? market.outcomes[0] : 'YES',
                          pct: market.yesPct, color: style.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: _BigOdds(label: market.outcomes.length > 1 ? market.outcomes[1] : 'NO',
                          pct: market.noPct, color: const Color(0xFFFF4D6D))),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Full chart
                  _FullChart(yesPrice: market.yesPrice, color: style.primary),
                  const SizedBox(height: 20),

                  // Stats
                  _StatsGrid(market: market, primary: style.primary),
                  const SizedBox(height: 20),

                  // Description
                  if (market.description != null && market.description!.isNotEmpty) ...[
                    Text('About', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      market.description!,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBetBar(context, style.primary),
    );
  }

  Widget _buildBetBar(BuildContext context, Color primary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                HapticFeedback.mediumImpact();
                final result = await showBetDialog(context, market);
                if (result != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Bet placed: \$${result.amount} on ${result.outcome}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    backgroundColor: primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, primary.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.black),
                      const SizedBox(width: 6),
                      Text('Place Bet', style: GoogleFonts.inter(
                        color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg(List<Color> colors) => Container(
    decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
  );
}

class _BigOdds extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;

  const _BigOdds({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$pct%', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: Colors.white54)),
        ],
      ),
    );
  }
}

class _FullChart extends StatelessWidget {
  final double yesPrice;
  final Color color;

  const _FullChart({required this.yesPrice, required this.color});

  @override
  Widget build(BuildContext context) {
    final rng = Random(yesPrice.hashCode);
    const points = 30;
    final spots = <FlSpot>[];
    double price = 0.5 + (rng.nextDouble() - 0.5) * 0.3;
    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      final target = price + (yesPrice - price) * (t * t);
      final noise = (rng.nextDouble() - 0.5) * 0.07 * (1 - t);
      price = (target + noise).clamp(0.02, 0.98);
      spots.add(FlSpot(i.toDouble(), price));
    }
    spots[points - 1] = FlSpot((points - 1).toDouble(), yesPrice.clamp(0.02, 0.98));

    return Container(
      height: 160,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  '${(v * 100).round()}%',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                ),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
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
}

class _StatsGrid extends StatelessWidget {
  final Market market;
  final Color primary;

  const _StatsGrid({required this.market, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Volume', value: market.volumeFormatted, icon: Icons.bar_chart_rounded, color: primary)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(
          label: 'Ends',
          value: market.endDate != null ? _formatDate(market.endDate!) : 'N/A',
          icon: Icons.event_rounded,
          color: primary,
        )),
      ],
    );
  }

  String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
