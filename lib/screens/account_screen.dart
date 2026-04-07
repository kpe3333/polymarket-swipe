import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_settings.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _settings = AppSettings();
  final _walletCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();

  static const _categories = [
    'Politics', 'Crypto', 'Sports', 'Science', 'Finance', 'Entertainment', 'World', 'Other'
  ];

  static const _betOptions = [5.0, 10.0, 25.0, 50.0, 100.0];
  static const _volumeOptions = [0.0, 1000.0, 10000.0, 100000.0];
  static const _daysOptions = [0, 7, 30, 90];

  @override
  void initState() {
    super.initState();
    _walletCtrl.text = _settings.walletAddress;
    _apiKeyCtrl.text = _settings.apiKey;
  }

  @override
  void dispose() {
    _walletCtrl.dispose();
    _apiKeyCtrl.dispose();
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
            SliverToBoxAdapter(child: _buildSection('💰 Betting')),
            SliverToBoxAdapter(child: _buildBettingSection()),
            SliverToBoxAdapter(child: _buildSection('🔗 Wallet & API')),
            SliverToBoxAdapter(child: _buildWalletSection()),
            SliverToBoxAdapter(child: _buildSection('📊 Feed Filters')),
            SliverToBoxAdapter(child: _buildFiltersSection()),
            SliverToBoxAdapter(child: _buildSection('🏷️ Categories')),
            SliverToBoxAdapter(child: _buildCategoriesSection()),
            SliverToBoxAdapter(child: _buildSection('🎨 Appearance')),
            SliverToBoxAdapter(child: _buildAppearanceSection()),
            SliverToBoxAdapter(child: _buildSection('ℹ️ About')),
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
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF00D09E),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D2000), Color(0xFF1A1400)],
          ),
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
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Undo skips • Advanced filters • Alerts',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$4.99/mo',
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildBettingSection() {
    return _Card(
      children: [
        Text('Default bet size', style: _labelStyle()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _betOptions.map((v) {
            final selected = _settings.defaultBet == v;
            return GestureDetector(
              onTap: () => setState(() => _settings.setDefaultBet(v)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00D09E).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF00D09E) : Colors.white12,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  '\$${v.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: selected ? const Color(0xFF00D09E) : Colors.white54,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWalletSection() {
    return _Card(
      children: [
        _InputField(
          label: 'Wallet Address',
          controller: _walletCtrl,
          hint: '0x...',
          icon: Icons.account_balance_wallet_outlined,
          onChanged: _settings.setWalletAddress,
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Polymarket API Key',
          controller: _apiKeyCtrl,
          hint: 'Enter API key',
          icon: Icons.key_outlined,
          obscure: true,
          onChanged: _settings.setApiKey,
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return _Card(
      children: [
        // Min volume
        Text('Minimum volume', style: _labelStyle()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _volumeOptions.map((v) {
            final selected = _settings.minVolume == v;
            final label = v == 0 ? 'Any' : v >= 1000000 ? '\$${(v/1000000).toStringAsFixed(0)}M' : '\$${(v/1000).toStringAsFixed(0)}K';
            return _FilterChip(
              label: label,
              selected: selected,
              onTap: () => setState(() => _settings.setMinVolume(v)),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),

        // Days left
        Text('Time remaining', style: _labelStyle()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _daysOptions.map((d) {
            final selected = _settings.maxDaysLeft == d;
            final label = d == 0 ? 'Any' : '$d days';
            return _FilterChip(
              label: label,
              selected: selected,
              onTap: () => setState(() => _settings.setMaxDaysLeft(d)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return _Card(
      children: [
        Text(
          'Show markets from these categories (empty = all)',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((cat) {
            final selected = _settings.selectedCategories.contains(cat);
            return GestureDetector(
              onTap: () => setState(() => _settings.toggleCategory(cat)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF00D09E).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xFF00D09E) : Colors.white12,
                  ),
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    color: selected ? const Color(0xFF00D09E) : Colors.white38,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _Card(
      children: [
        ListenableBuilder(
          listenable: _settings,
          builder: (_, __) => _SettingRow(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            trailing: Switch(
              value: _settings.darkMode,
              onChanged: (v) => setState(() => _settings.setDarkMode(v)),
              activeColor: const Color(0xFF00D09E),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _Card(
      children: [
        _SettingRow(
          icon: Icons.info_outline_rounded,
          label: 'Version',
          trailing: Text('1.0.0', style: GoogleFonts.inter(color: Colors.white38)),
        ),
        const Divider(color: Colors.white10, height: 1),
        _SettingRow(
          icon: Icons.open_in_new_rounded,
          label: 'Polymarket',
          onTap: () {},
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ),
        const Divider(color: Colors.white10, height: 1),
        _SettingRow(
          icon: Icons.bug_report_outlined,
          label: 'Report a bug',
          onTap: () {},
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ),
      ],
    );
  }

  TextStyle _labelStyle() => GoogleFonts.inter(
    color: Colors.white70,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );
}

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingRow({required this.icon, required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
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

  const _InputField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onChanged,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600),
        ),
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
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00D09E)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF00D09E).withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFF00D09E) : Colors.white12),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFF00D09E) : Colors.white38,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
