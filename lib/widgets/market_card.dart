import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';

class MarketCard extends StatelessWidget {
  final Market market;
  final double swipeProgress; // -1.0 (left) to 1.0 (right)

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildQuestion(),
                  const Spacer(),
                  _buildOddsBar(),
                  const SizedBox(height: 20),
                  _buildStats(),
                ],
              ),
            ),

            // Swipe overlay — BET (right)
            if (swipeProgress > 0.05)
              Positioned(
                top: 32,
                left: 24,
                child: _SwipeLabel(
                  label: 'BET',
                  color: const Color(0xFF00D09E),
                  opacity: swipeProgress.clamp(0.0, 1.0),
                ),
              ),

            // Swipe overlay — SKIP (left)
            if (swipeProgress < -0.05)
              Positioned(
                top: 32,
                right: 24,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF00D09E),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const Spacer(),
        if (market.endDate != null)
          Text(
            _formatDeadline(market.endDate!),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Text(
      market.question,
      style: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.3,
      ),
      maxLines: 5,
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
            height: 10,
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
        _StatChip(
          icon: Icons.bar_chart_rounded,
          label: 'Vol ${market.volumeFormatted}',
        ),
        const SizedBox(width: 10),
        _StatChip(
          icon: Icons.people_outline_rounded,
          label: 'Polymarket',
        ),
      ],
    );
  }

  String _formatDeadline(DateTime date) {
    final diff = date.difference(DateTime.now());
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo left';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return 'Ending soon';
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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white38,
              fontWeight: FontWeight.w500,
            ),
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

  const _SwipeLabel({
    required this.label,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 22,
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
      ..color = Colors.white.withOpacity(0.03)
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
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
