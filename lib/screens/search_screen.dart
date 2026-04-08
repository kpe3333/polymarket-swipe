import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bet.dart';
import '../models/market.dart';
import '../services/polymarket_service.dart';
import '../widgets/market_card.dart';
import '../widgets/bet_dialog.dart';
import '../utils/haptic.dart';
import 'market_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = PolymarketService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // All loaded markets (for text search)
  List<Market> _all = [];
  // Browse-mode list (paginated infinite scroll)
  List<Market> _browse = [];
  List<Market> _results = [];

  bool _loading = false;
  bool _initialLoad = false;
  bool _browseLoading = false;
  bool _browseHasMore = true;
  int _browseOffset = 0;

  String _query = '';
  String? _selectedCategory; // null = no category filter active

  static const _pageSize = 100;

  static const _categories = [
    'All',
    'Politics',
    'Crypto',
    'Sports',
    'Finance',
    'Science',
    'Entertainment',
    'World',
    'Other',
  ];

  static const _trending = ['Trump', 'Bitcoin', 'NBA', 'Fed rate', 'AI', 'Election'];

  Set<String> get _betMarketIds => BetStore().bets.map((b) => b.marketId).toSet();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadAll();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final markets = await _service.fetchMarkets(limit: 100);
      setState(() { _all = markets; _loading = false; _initialLoad = true; });
    } catch (_) {
      setState(() { _loading = false; _initialLoad = true; });
    }
  }

  Future<void> _startBrowse(String? category) async {
    setState(() {
      _selectedCategory = category;
      _browse = [];
      _browseOffset = 0;
      _browseHasMore = true;
      _browseLoading = true;
    });
    await _loadMoreBrowse();
  }

  Future<void> _loadMoreBrowse() async {
    if (_browseLoading && _browseOffset > 0) return;
    setState(() => _browseLoading = true);
    try {
      // For category-filtered browsing, fetch multiple pages until we accumulate
      // at least 10 matching markets (or run out)
      int addedCount = 0;
      bool hasMore = true;
      while (addedCount < 10 && hasMore) {
        final fresh = await _service.fetchMarkets(limit: _pageSize, offset: _browseOffset);
        if (fresh.isEmpty) { hasMore = false; break; }
        final betIds = _betMarketIds;
        final filtered = fresh.where((m) {
          if (betIds.contains(m.id)) return false;
          if (_selectedCategory == null || _selectedCategory == 'All') return true;
          return m.category == _selectedCategory;
        }).toList();
        _browse.addAll(filtered);
        addedCount += filtered.length;
        _browseOffset += fresh.length;
        hasMore = fresh.length == _pageSize;
        // For "All" category, don't keep fetching
        if (_selectedCategory == null || _selectedCategory == 'All') break;
      }
      if (mounted) {
        setState(() {
          _browseHasMore = hasMore;
          _browseLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _browseLoading = false);
    }
  }

  void _onScroll() {
    if (_selectedCategory != null &&
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 300 &&
        !_browseLoading && _browseHasMore) {
      _loadMoreBrowse();
    }
  }

  void _onSearch(String q) {
    final betIds = _betMarketIds;
    setState(() {
      _query = q.trim().toLowerCase();
      if (_query.isEmpty) {
        _results = [];
      } else {
        _results = _all.where((m) {
          if (betIds.contains(m.id)) return false;
          final matchesCategory = _selectedCategory == null || _selectedCategory == 'All' || m.category == _selectedCategory;
          final matchesText = m.question.toLowerCase().contains(_query) ||
              (m.category?.toLowerCase().contains(_query) ?? false) ||
              (m.description?.toLowerCase().contains(_query) ?? false);
          return matchesCategory && matchesText;
        }).toList();
      }
    });
  }

  void _clearCategory() {
    setState(() {
      _selectedCategory = null;
      _browse = [];
    });
  }

  void _openDetail(Market m) {
    Haptic.selection();
    FocusScope.of(context).unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => MarketDetailScreen(market: m)));
  }

  Future<void> _openBet(Market m) async {
    Haptic.medium();
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final result = await showBetDialog(context, m);
    if (result != null && mounted) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: TextField(
          controller: _ctrl,
          onChanged: _onSearch,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search markets…',
            hintStyle: GoogleFonts.inter(color: Colors.white24),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white24, size: 22),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
                    onPressed: () { _ctrl.clear(); _onSearch(''); },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final sel = _selectedCategory == cat;
          return GestureDetector(
            onTap: () {
              Haptic.selection();
              if (sel) {
                _clearCategory();
              } else {
                _startBrowse(cat);
                if (_query.isNotEmpty) _onSearch(_query);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF00D09E).withOpacity(0.18) : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? const Color(0xFF00D09E) : Colors.white.withOpacity(0.1),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  color: sel ? const Color(0xFF00D09E) : Colors.white54,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)));
    }

    // Text search active
    if (_query.isNotEmpty) {
      if (_results.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No results for "$_query"',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 15)),
            ],
          ),
        );
      }
      return ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: _results.length,
        itemBuilder: (_, i) => _SearchResultCard(
          market: _results[i],
          onTap: () => _openDetail(_results[i]),
          onBet: () => _openBet(_results[i]),
        ),
      );
    }

    // Browse mode (category selected)
    if (_selectedCategory != null) {
      return ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: _browse.length + 1,
        itemBuilder: (_, i) {
          if (i == _browse.length) {
            return _browseLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF00D09E))),
                  )
                : _browseHasMore
                    ? const SizedBox(height: 20)
                    : Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text('All caught up!',
                              style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
                        ),
                      );
          }
          return _SearchResultCard(
            market: _browse[i],
            onTap: () => _openDetail(_browse[i]),
            onBet: () => _openBet(_browse[i]),
          );
        },
      );
    }

    // Default: no query, no category — show trending + top
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔥 Trending',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _trending.map((t) => GestureDetector(
              onTap: () { _ctrl.text = t; _onSearch(t); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF00D09E)),
                    const SizedBox(width: 6),
                    Text(t, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            )).toList(),
          ),
          if (_initialLoad && _all.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('🕐 Top by Volume',
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ..._all.where((m) => !_betMarketIds.contains(m.id)).take(5).map((m) => _SearchResultCard(
              market: m,
              onTap: () => _openDetail(m),
              onBet: () => _openBet(m),
            )),
          ],
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Market market;
  final VoidCallback onTap;
  final VoidCallback onBet;

  const _SearchResultCard({required this.market, required this.onTap, required this.onBet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            if (market.image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(market.image!, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48)),
              ),
            if (market.image != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (market.category != null)
                    Text(market.category!.toUpperCase(),
                        style: GoogleFonts.inter(
                            color: const Color(0xFF00D09E), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(market.question,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${market.yesPct}% YES',
                          style: GoogleFonts.inter(color: const Color(0xFF00D09E), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('Vol ${market.volumeFormatted}',
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onBet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00D09E).withOpacity(0.4)),
                ),
                child: Text('BET',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF00D09E), fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
