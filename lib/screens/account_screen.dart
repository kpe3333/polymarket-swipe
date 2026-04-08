import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_settings.dart';
import '../models/viewed_markets.dart';
import '../services/translation_service.dart';
import '../utils/haptic.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _settings = AppSettings();
  final _walletCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  late final TextEditingController _betDollarsCtrl;
  late final TextEditingController _betCentsCtrl;
  bool _apiKeyObscured = true;

  static const _categories = [
    'Politics', 'Crypto', 'Sports', 'Science', 'Finance', 'Entertainment', 'World', 'Other',
  ];
  static const _betOptions = [0.10, 1.0, 5.0, 10.0, 25.0, 50.0, 100.0];
  static const _volumeOptions = [0.0, 1000.0, 10000.0, 100000.0];
  static const _daysOptions = [0, 7, 30, 90];
  static const _hapticLabels = ['Off', 'Light', 'Medium', 'Heavy'];

  @override
  void initState() {
    super.initState();
    _walletCtrl.text = _settings.walletAddress;
    _apiKeyCtrl.text = _settings.apiKey;
    _syncBetControllers();
  }

  void _syncBetControllers() {
    final bet = _settings.defaultBet.clamp(0.10, double.infinity);
    _betDollarsCtrl = TextEditingController(text: '${bet.floor()}');
    _betCentsCtrl = TextEditingController(
      text: '${((bet - bet.floor()) * 100).round()}'.padLeft(2, '0'),
    );
  }

  void _onBetCustomChanged() {
    final d = int.tryParse(_betDollarsCtrl.text) ?? 0;
    final c = (int.tryParse(_betCentsCtrl.text) ?? 0).clamp(0, 99);
    final v = (d + c / 100.0).clamp(0.10, double.infinity);
    _settings.setDefaultBet(v);
    setState(() {});
  }

  @override
  void dispose() {
    _walletCtrl.dispose();
    _apiKeyCtrl.dispose();
    _betDollarsCtrl.dispose();
    _betCentsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildPremiumBanner()),
            SliverToBoxAdapter(child: _sectionTitle('💰 Betting')),
            SliverToBoxAdapter(child: _buildBettingSection()),
            SliverToBoxAdapter(child: _sectionTitle('🔗 Wallet & API')),
            SliverToBoxAdapter(child: _buildWalletSection()),
            SliverToBoxAdapter(child: _sectionTitle('📊 Feed Filters')),
            SliverToBoxAdapter(child: _buildFiltersSection()),
            SliverToBoxAdapter(child: _sectionTitle('🏷️ Categories')),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            SliverToBoxAdapter(child: _sectionTitle('🎨 Appearance')),
            SliverToBoxAdapter(child: _buildAppearanceSection()),
            SliverToBoxAdapter(child: _sectionTitle('📳 Haptic Feedback')),
            SliverToBoxAdapter(child: _buildHapticSection()),
            SliverToBoxAdapter(child: _sectionTitle('🌐 Language')),
            SliverToBoxAdapter(child: _buildLanguageSection()),
            SliverToBoxAdapter(child: _sectionTitle('ℹ️ About')),
            SliverToBoxAdapter(child: _buildAboutSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        'ACCOUNT',
        style: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w900,
          color: const Color(0xFF00D09E), letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GestureDetector(
        onTap: () {
          Haptic.medium();
          _showPremiumDialog();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2D2000), Color(0xFF1A1400)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upgrade to Premium',
                        style: GoogleFonts.inter(color: const Color(0xFFFFD700), fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('Undo skips • Advanced filters • Alerts',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(12)),
                child: Text('\$4.99/mo',
                    style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(title,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
    );
  }

  // ── BETTING ──────────────────────────────────────────────
  Widget _buildBettingSection() {
    return _Card(children: [
      Text('Default bet size', style: _label()),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _betOptions.map((v) {
          final sel = (_settings.defaultBet - v).abs() < 0.001;
          final label = v < 1.0 ? '${(v * 100).round()}¢' : '\$${v.toStringAsFixed(0)}';
          return _ChipButton(
            label: label,
            selected: sel,
            color: const Color(0xFF00D09E),
            onTap: () async {
              Haptic.selection();
              await _settings.setDefaultBet(v);
              _betDollarsCtrl.text = '${v.floor()}';
              _betCentsCtrl.text = '${((v - v.floor()) * 100).round()}'.padLeft(2, '0');
              setState(() {});
            },
          );
        }).toList(),
      ),
      const SizedBox(height: 14),
      Text('Or enter custom amount:', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: _BetAmountField(
              controller: _betDollarsCtrl,
              prefix: '\$',
              hint: '0',
              onChanged: (_) => _onBetCustomChanged(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('.', style: GoogleFonts.inter(color: Colors.white54, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 2,
            child: _BetAmountField(
              controller: _betCentsCtrl,
              prefix: '¢',
              hint: '00',
              maxLength: 2,
              onChanged: (_) => _onBetCustomChanged(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D09E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D09E).withOpacity(0.4)),
            ),
            child: Text(
              '\$${_settings.defaultBet.toStringAsFixed(2)}',
              style: GoogleFonts.inter(color: const Color(0xFF00D09E), fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    ]);
  }

  // ── WALLET ───────────────────────────────────────────────
  Widget _buildWalletSection() {
    return _Card(children: [
      _InputField(
        label: 'Wallet Address',
        controller: _walletCtrl,
        hint: '0x...',
        icon: Icons.account_balance_wallet_outlined,
        onChanged: _settings.setWalletAddress,
        trailing: _walletCtrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white38),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _walletCtrl.text));
                  Haptic.light();
                  _snack('Address copied', const Color(0xFF00D09E));
                },
              )
            : null,
      ),
      const SizedBox(height: 16),
      _InputField(
        label: 'Polymarket API Key',
        controller: _apiKeyCtrl,
        hint: 'Enter API key',
        icon: Icons.key_outlined,
        obscure: _apiKeyObscured,
        onChanged: _settings.setApiKey,
        trailing: IconButton(
          icon: Icon(_apiKeyObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              size: 18, color: Colors.white38),
          onPressed: () => setState(() => _apiKeyObscured = !_apiKeyObscured),
        ),
      ),
      if (_apiKeyCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                _apiKeyCtrl.clear();
                _settings.setApiKey('');
                Haptic.light();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFFF4D6D)),
              label: Text('Clear key', style: GoogleFonts.inter(color: const Color(0xFFFF4D6D), fontSize: 12)),
            ),
          ],
        ),
      ],
    ]);
  }

  // ── FILTERS ──────────────────────────────────────────────
  Widget _buildFiltersSection() {
    return _Card(children: [
      Text('Minimum volume', style: _label()),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: _volumeOptions.map((v) {
        final label = v == 0 ? 'Any'
            : v >= 1000000 ? '\$${(v / 1000000).toStringAsFixed(0)}M'
            : '\$${(v / 1000).toStringAsFixed(0)}K';
        return _ChipButton(
          label: label,
          selected: _settings.minVolume == v,
          color: const Color(0xFF00D09E),
          onTap: () async { Haptic.selection(); await _settings.setMinVolume(v); setState(() {}); },
        );
      }).toList()),

      const SizedBox(height: 16),
      const Divider(color: Colors.white10),
      const SizedBox(height: 16),

      Text('Time remaining', style: _label()),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: _daysOptions.map((d) {
        final label = d == 0 ? 'Any' : '< $d days';
        return _ChipButton(
          label: label,
          selected: _settings.maxDaysLeft == d,
          color: const Color(0xFF00D09E),
          onTap: () async { Haptic.selection(); await _settings.setMaxDaysLeft(d); setState(() {}); },
        );
      }).toList()),
    ]);
  }

  // ── CATEGORIES ───────────────────────────────────────────
  Widget _buildCategoriesSection() {
    return _Card(children: [
      Row(
        children: [
          Expanded(
            child: Text('Empty = show all categories',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
          ),
          if (_settings.selectedCategories.isNotEmpty)
            TextButton(
              onPressed: () {
                Haptic.light();
                setState(() {
                  for (final c in List.from(_settings.selectedCategories)) {
                    _settings.toggleCategory(c);
                  }
                });
              },
              child: Text('Clear all', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _categories.map((cat) {
          final sel = _settings.selectedCategories.contains(cat);
          return _ChipButton(
            label: cat,
            selected: sel,
            color: const Color(0xFF00D09E),
            onTap: () async { Haptic.selection(); await _settings.toggleCategory(cat); setState(() {}); },
          );
        }).toList(),
      ),
    ]);
  }

  // ── APPEARANCE ───────────────────────────────────────────
  Widget _buildAppearanceSection() {
    return _Card(children: [
      _Row(
        icon: Icons.dark_mode_rounded,
        label: 'Dark Mode',
        trailing: Switch(
          value: _settings.darkMode,
          onChanged: (v) async { Haptic.light(); await _settings.setDarkMode(v); setState(() {}); },
          activeColor: const Color(0xFF00D09E),
        ),
      ),
    ]);
  }

  // ── HAPTIC ───────────────────────────────────────────────
  Widget _buildHapticSection() {
    return _Card(children: [
      Text('Intensity', style: _label()),
      const SizedBox(height: 12),
      Row(
        children: List.generate(_hapticLabels.length, (i) {
          final sel = _settings.hapticLevel == i;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                await _settings.setHapticLevel(i);
                Haptic.demoForLevel(i);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF00D09E).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? const Color(0xFF00D09E) : Colors.white12),
                ),
                child: Text(
                  _hapticLabels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: sel ? const Color(0xFF00D09E) : Colors.white38,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ]);
  }

  // ── LANGUAGE ─────────────────────────────────────────────
  Widget _buildLanguageSection() {
    final ts = TranslationService();
    final langs = TranslationService.availableLanguages;

    return _Card(children: [
      // Mode selector
      Text('Card language mode', style: _label()),
      const SizedBox(height: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LangModeOption(
            label: 'English only',
            subtitle: 'Show market questions in English',
            selected: ts.mode == LangMode.english,
            onTap: () async {
              Haptic.selection();
              ts.mode = LangMode.english;
              await ts.save();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _LangModeOption(
            label: 'Manual — 1 language',
            subtitle: 'Translate cards to selected language',
            selected: ts.mode == LangMode.manual && ts.secondaryLang == null,
            onTap: () async {
              Haptic.selection();
              ts.mode = LangMode.manual;
              ts.secondaryLang = null;
              await ts.save();
              setState(() {});
            },
          ),
          const SizedBox(height: 8),
          _LangModeOption(
            label: 'Manual — 2 languages',
            subtitle: 'Primary large + secondary small below',
            selected: ts.mode == LangMode.manual && ts.secondaryLang != null,
            onTap: () async {
              Haptic.selection();
              ts.mode = LangMode.manual;
              ts.secondaryLang ??= 'ru';
              await ts.save();
              setState(() {});
            },
          ),
        ],
      ),

      // Primary language picker (manual mode only)
      if (ts.mode == LangMode.manual) ...[
        const SizedBox(height: 20),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),
        Text('Primary language', style: _label()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: langs.entries.map((e) {
            final sel = ts.primaryLang == e.key;
            // Skip 'en' from primary when in manual mode — user can stay in English mode instead
            return _ChipButton(
              label: e.value,
              selected: sel,
              color: const Color(0xFF00D09E),
              onTap: () async {
                Haptic.selection();
                ts.primaryLang = e.key;
                await ts.save();
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],

      // Secondary language picker (manual 2-lang mode only)
      if (ts.mode == LangMode.manual && ts.secondaryLang != null) ...[
        const SizedBox(height: 16),
        Text('Secondary language', style: _label()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: langs.entries.map((e) {
            final sel = ts.secondaryLang == e.key;
            return _ChipButton(
              label: e.value,
              selected: sel,
              color: const Color(0xFFFF9500),
              onTap: () async {
                Haptic.selection();
                ts.secondaryLang = e.key;
                await ts.save();
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],

    ]);
  }

  // ── ABOUT ────────────────────────────────────────────────
  Widget _buildAboutSection() {
    return _Card(children: [
      _Row(
        icon: Icons.info_outline_rounded,
        label: 'Version',
        trailing: Text('1.0.0', style: GoogleFonts.inter(color: Colors.white38)),
      ),
      const Divider(color: Colors.white10, height: 1),
      _Row(
        icon: Icons.open_in_new_rounded,
        label: 'Open Polymarket',
        onTap: () {
          Haptic.light();
          _snack('Opening polymarket.com…', Colors.white24);
        },
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ),
      const Divider(color: Colors.white10, height: 1),
      _Row(
        icon: Icons.bug_report_outlined,
        label: 'Report a bug',
        onTap: () {
          Haptic.light();
          _snack('Sending feedback…', Colors.white24);
        },
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      ),
      const Divider(color: Colors.white10, height: 1),
      _Row(
        icon: Icons.history_outlined,
        label: 'Clear viewed history',
        onTap: () async {
          await ViewedStore().clear();
          Haptic.light();
          _snack('Viewed history cleared — feed refreshed', const Color(0xFF00D09E));
          setState(() {});
        },
        trailing: Text('${ViewedStore().count} seen',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 12)),
      ),
      const Divider(color: Colors.white10, height: 1),
      _Row(
        icon: Icons.delete_forever_outlined,
        label: 'Reset all settings',
        onTap: _confirmReset,
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFFF4D6D)),
      ),
    ]);
  }

  // ── Helpers ──────────────────────────────────────────────
  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    ));
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24),
          const SizedBox(width: 8),
          Text('Premium', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coming soon!', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 8),
            ...['Undo skipped cards', 'Advanced filters', 'Portfolio analytics', 'Price alerts']
                .map((f) => Padding(
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
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Got it', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset settings?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('All settings will return to defaults.', style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _settings.setDefaultBet(10.0);
              _settings.setDarkMode(true);
              _settings.setMinVolume(0);
              _settings.setMaxDaysLeft(0);
              _settings.setHapticLevel(2);
              _settings.setWalletAddress('');
              _settings.setApiKey('');
              _walletCtrl.clear();
              _apiKeyCtrl.clear();
              Haptic.medium();
              setState(() {});
              _snack('Settings reset', const Color(0xFF00D09E));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D6D), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Reset', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  TextStyle _label() => GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14);
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Row({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(children: [
          Icon(icon, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14))),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Function(String) onChanged;
  final Widget? trailing;

  const _InputField({
    required this.label, required this.controller,
    required this.hint, required this.icon,
    required this.onChanged,
    this.obscure = false, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white24),
          prefixIcon: Icon(icon, color: Colors.white24, size: 18),
          suffixIcon: trailing,
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00D09E))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }
}

class _LangModeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangModeOption({
    required this.label, required this.subtitle,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D09E);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? accent : Colors.white12, width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: selected ? accent : Colors.white24, width: 2),
              color: selected ? accent : Colors.transparent,
            ),
            child: selected ? const Icon(Icons.check, size: 11, color: Colors.black) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.inter(
                color: selected ? accent : Colors.white70,
                fontWeight: FontWeight.w600, fontSize: 13,
              )),
              Text(subtitle, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _BetAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String prefix;
  final String hint;
  final int maxLength;
  final void Function(String) onChanged;

  const _BetAmountField({
    required this.controller, required this.prefix, required this.hint,
    this.maxLength = 6, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D09E);
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
        prefixStyle: GoogleFonts.inter(color: accent, fontSize: 15, fontWeight: FontWeight.w700),
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ChipButton({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.white12, width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
              color: selected ? color : Colors.white38,
              fontWeight: FontWeight.w700, fontSize: 13,
            )),
      ),
    );
  }
}
