import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../models/app_settings.dart';
import '../utils/category_colors.dart';

Future<BetResult?> showBetDialog(BuildContext context, Market market) {
  return showModalBottomSheet<BetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BetDialog(market: market),
  );
}

class BetResult {
  final String outcome;
  final double amount;
  BetResult({required this.outcome, required this.amount});
}

class BetDialog extends StatefulWidget {
  final Market market;
  const BetDialog({super.key, required this.market});

  @override
  State<BetDialog> createState() => _BetDialogState();
}

class _BetDialogState extends State<BetDialog> {
  final _settings = AppSettings();
  String? _selectedOutcome;
  late double _amount;

  static const _quickAmounts = [5.0, 10.0, 25.0, 50.0, 100.0];

  @override
  void initState() {
    super.initState();
    _amount = _settings.defaultBet;
  }

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(widget.market.category);
    final yes = widget.market.outcomes.isNotEmpty ? widget.market.outcomes[0] : 'YES';
    final no = widget.market.outcomes.length > 1 ? widget.market.outcomes[1] : 'NO';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Question
              Text(
                widget.market.question,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),

              // YES / NO buttons
              Text(
                'Your prediction',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _OutcomeButton(
                    label: yes,
                    pct: widget.market.yesPct,
                    color: style.primary,
                    selected: _selectedOutcome == yes,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedOutcome = yes);
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _OutcomeButton(
                    label: no,
                    pct: widget.market.noPct,
                    color: const Color(0xFFFF4D6D),
                    selected: _selectedOutcome == no,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedOutcome = no);
                    },
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // Amount
              Text(
                'Amount (USDC)',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _quickAmounts.map((v) {
                  final selected = _amount == v;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _amount = v);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? style.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? style.primary : Colors.white12,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        '\$${v.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: selected ? style.primary : Colors.white38,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Potential return
              if (_selectedOutcome != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Potential return', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                      Text(
                        '\$${_calcReturn().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          color: style.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Confirm button
              AnimatedOpacity(
                opacity: _selectedOutcome != null ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _selectedOutcome != null ? _confirm : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _selectedOutcome != null
                            ? [style.primary, style.primary.withOpacity(0.7)]
                            : [Colors.white12, Colors.white12],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _selectedOutcome != null
                            ? 'Place Bet — \$$_amount on $_selectedOutcome'
                            : 'Select YES or NO first',
                        style: GoogleFonts.inter(
                          color: _selectedOutcome != null ? Colors.black : Colors.white24,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calcReturn() {
    if (_selectedOutcome == null) return 0;
    final yes = widget.market.outcomes.isNotEmpty ? widget.market.outcomes[0] : 'YES';
    final price = _selectedOutcome == yes ? widget.market.yesPrice : widget.market.noPrice;
    if (price <= 0) return 0;
    return _amount / price;
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, BetResult(outcome: _selectedOutcome!, amount: _amount));
  }
}

class _OutcomeButton extends StatelessWidget {
  final String label;
  final int pct;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OutcomeButton({
    required this.label,
    required this.pct,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$pct%',
              style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
