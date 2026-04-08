import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../utils/haptic.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/market.dart';
import '../models/app_settings.dart';
import '../models/bet.dart';
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

  late final TextEditingController _dollarsCtrl;
  late final TextEditingController _centsCtrl;

  static const _baseAmounts = [1.0, 5.0, 10.0, 25.0, 50.0, 100.0];

  List<double> get _quickAmounts {
    final def = _settings.defaultBet.clamp(0.10, double.infinity);
    // Put defaultBet first, then remaining values larger than it
    if (_baseAmounts.contains(def)) {
      return [def, ..._baseAmounts.where((v) => v != def)];
    }
    return [def, ..._baseAmounts.where((v) => v > def)];
  }

  @override
  void initState() {
    super.initState();
    _amount = _settings.defaultBet.clamp(0.10, double.infinity);
    _dollarsCtrl = TextEditingController(text: '${_amount.floor()}');
    _centsCtrl = TextEditingController(
      text: '${((_amount - _amount.floor()) * 100).round()}'.padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _dollarsCtrl.dispose();
    _centsCtrl.dispose();
    super.dispose();
  }

  void _setAmount(double v) {
    final clamped = v.clamp(0.10, double.infinity);
    setState(() { _amount = clamped; });
    _dollarsCtrl.text = '${clamped.floor()}';
    _centsCtrl.text = '${((clamped - clamped.floor()) * 100).round()}'.padLeft(2, '0');
  }

  void _onCustomChanged() {
    final d = int.tryParse(_dollarsCtrl.text) ?? 0;
    final c = (int.tryParse(_centsCtrl.text) ?? 0).clamp(0, 99);
    final v = (d + c / 100.0).clamp(0.10, double.infinity);
    setState(() => _amount = v);
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
                      Haptic.selection();
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
                      Haptic.selection();
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
                spacing: 8, runSpacing: 8,
                children: _quickAmounts.map((v) {
                  final selected = (_amount - v).abs() < 0.001;
                  final label = v < 1.0 ? '${(v * 100).round()}¢' : '\$${v.toStringAsFixed(0)}';
                  return GestureDetector(
                    onTap: () { Haptic.selection(); _setAmount(v); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? style.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? style.primary : Colors.white12,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: selected ? style.primary : Colors.white38,
                          fontWeight: FontWeight.w700, fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              // Custom dollar + cent input
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _AmountField(
                      controller: _dollarsCtrl,
                      prefix: '\$',
                      hint: '0',
                      onChanged: (_) => _onCustomChanged(),
                      primary: style.primary,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    flex: 2,
                    child: _AmountField(
                      controller: _centsCtrl,
                      prefix: '¢',
                      hint: '00',
                      maxLength: 2,
                      onChanged: (_) => _onCustomChanged(),
                      primary: style.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: style.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: style.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Total: \$${_amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: style.primary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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
                            ? 'Place Bet — \$${_amount.toStringAsFixed(2)} on $_selectedOutcome'
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
    Haptic.heavy();
    final yes = widget.market.outcomes.isNotEmpty ? widget.market.outcomes[0] : 'YES';
    final price = _selectedOutcome == yes ? widget.market.yesPrice : widget.market.noPrice;
    BetStore().addBet(Bet(
      id: const Uuid().v4(),
      marketId: widget.market.id,
      question: widget.market.question,
      outcome: _selectedOutcome!,
      amount: _amount,
      price: price,
      placedAt: DateTime.now(),
      image: widget.market.image,
      category: widget.market.category,
    ));
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

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String prefix;
  final String hint;
  final int maxLength;
  final void Function(String) onChanged;
  final Color primary;

  const _AmountField({
    required this.controller, required this.prefix, required this.hint,
    this.maxLength = 6, required this.onChanged, required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        counterText: '',
        prefixText: prefix,
        prefixStyle: GoogleFonts.inter(color: primary, fontSize: 15, fontWeight: FontWeight.w700),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}
