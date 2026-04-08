import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../services/translation_service.dart';
import '../utils/category_colors.dart';

class MarketCard extends StatefulWidget {
  final Market market;
  final double swipeProgress;
  final VoidCallback? onTap;

  const MarketCard({
    super.key,
    required this.market,
    this.swipeProgress = 0.0,
    this.onTap,
  });

  @override
  State<MarketCard> createState() => _MarketCardState();
}

class _MarketCardState extends State<MarketCard> {
  final _ts = TranslationService();
  String? _translatedQuestion;
  String? _secondaryQuestion;

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    _ts.addListener(_onLangChanged);
  }

  void _onLangChanged() {
    if (!mounted) return;
    setState(() { _translatedQuestion = null; _secondaryQuestion = null; });
    _loadTranslations();
  }

  @override
  void dispose() {
    _ts.removeListener(_onLangChanged);
    super.dispose();
  }

  Future<void> _loadTranslations() async {
    final primary = _ts.activePrimaryLang;
    if (primary != 'en') {
      final t = await _ts.translate(widget.market.question, primary);
      if (mounted) setState(() => _translatedQuestion = t);
    }
    if (_ts.hasSecondary && _ts.secondaryLang != null) {
      final t2 = await _ts.translate(widget.market.question, _ts.secondaryLang!);
      if (mounted) setState(() => _secondaryQuestion = t2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.market;
    final swipeProgress = widget.swipeProgress;
    final style = categoryStyle(market.category);
    final betOpacity = swipeProgress.clamp(0.0, 1.0);
    final skipOpacity = (-swipeProgress).clamp(0.0, 1.0);

    // Tint overlay color when swiping
    Color? tintColor;
    if (swipeProgress > 0.05) tintColor = const Color(0xFF00D09E).withOpacity(betOpacity * 0.15);
    if (swipeProgress < -0.05) tintColor = const Color(0xFFFF4D6D).withOpacity(skipOpacity * 0.15);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: style.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: style.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: style.primary.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _GridPainter(style.primary))),

              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image header
                  if (market.image != null && market.image!.isNotEmpty)
                    _ImageHeader(imageUrl: market.image!, primary: style.primary, category: market.category)
                  else
                    _CategoryHeader(category: market.category, primary: style.primary),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuestion(),
                          if (market.description != null && market.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildDescription(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Chart
                  SizedBox(
                    height: 72,
                    child: _MiniChart(yesPrice: market.yesPrice, color: style.primary),
                  ),

                  // Odds + stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: Column(
                      children: [
                        _buildOddsBar(style.primary),
                        const SizedBox(height: 12),
                        _buildStats(style.primary),
                      ],
                    ),
                  ),
                ],
              ),

              // Swipe tint overlay
              if (tintColor != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: tintColor,
                    ),
                  ),
                ),

              // BET label
              if (swipeProgress > 0.05)
                Positioned(
                  top: 28,
                  left: 20,
                  child: _SwipeLabel(label: 'BET', color: const Color(0xFF00D09E), opacity: betOpacity),
                ),

              // SKIP label
              if (swipeProgress < -0.05)
                Positioned(
                  top: 28,
                  right: 20,
                  child: _SwipeLabel(label: 'SKIP', color: const Color(0xFFFF4D6D), opacity: skipOpacity),
                ),

              // Tap hint
              Positioned(
                bottom: 18,
                right: 20,
                child: Icon(Icons.open_in_full_rounded, size: 14, color: Colors.white12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    final displayText = _translatedQuestion ?? widget.market.question;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
        // Secondary language (smaller, below)
        if (_secondaryQuestion != null) ...[
          const SizedBox(height: 4),
          Text(
            _secondaryQuestion!,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white38, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.market.description!,
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white38, height: 1.4),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildOddsBar(Color primary) {
    final market = widget.market;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _OddsLabel(
              label: market.outcomes.isNotEmpty ? market.outcomes[0] : 'YES',
              pct: market.yesPct,
              color: primary,
            ),
            _OddsLabel(
              label: market.outcomes.length > 1 ? market.outcomes[1] : 'NO',
              pct: market.noPct,
              color: const Color(0xFFFF4D6D),
              align: TextAlign.right,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(flex: market.yesPct, child: Container(color: primary)),
                Expanded(flex: market.noPct, child: Container(color: const Color(0xFFFF4D6D))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(Color primary) {
    final market = widget.market;
    return Row(
      children: [
        _StatChip(icon: Icons.bar_chart_rounded, label: 'Vol ${market.volumeFormatted}'),
        const SizedBox(width: 8),
        if (market.endDate != null) ...[
          _StatChip(
            icon: Icons.schedule_rounded,
            label: _formatDeadline(market.endDate!),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withOpacity(0.4)),
          ),
          child: Text(
            '${market.yesPct}% YES',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
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

class _ImageHeader extends StatelessWidget {
  final String imageUrl;
  final Color primary;
  final String? category;

  const _ImageHeader({required this.imageUrl, required this.primary, this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(color: primary.withOpacity(0.1));
            },
            errorBuilder: (_, __, ___) => _CategoryHeader(category: category, primary: primary),
          ),
          // Gradient fade bottom
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          // Category chip on top of image
          Positioned(
            top: 12,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withOpacity(0.6)),
              ),
              child: Text(
                (category ?? 'MARKET').toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: primary, letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String? category;
  final Color primary;

  const _CategoryHeader({required this.category, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primary.withOpacity(0.4)),
            ),
            child: Text(
              (category ?? 'MARKET').toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

  List<FlSpot> _generateSpots(double endPrice) {
    final rng = Random(endPrice.hashCode);
    const points = 20;
    final spots = <FlSpot>[];
    double price = 0.5 + (rng.nextDouble() - 0.5) * 0.3;
    for (int i = 0; i < points; i++) {
      final t = i / (points - 1);
      final target = price + (endPrice - price) * (t * t);
      final noise = (rng.nextDouble() - 0.5) * 0.06 * (1 - t);
      price = (target + noise).clamp(0.02, 0.98);
      spots.add(FlSpot(i.toDouble(), price));
    }
    spots[points - 1] = FlSpot((points - 1).toDouble(), endPrice.clamp(0.02, 0.98));
    return spots;
  }
}

class _OddsLabel extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  final TextAlign align;

  const _OddsLabel({required this.label, required this.pct, required this.color, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text('$pct%', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white38),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white38)),
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
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.04)..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
