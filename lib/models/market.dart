import 'dart:convert';

class Market {
  final String id;
  final String question;
  final List<String> outcomes;
  final List<double> prices;
  final double volume;
  final DateTime? endDate;
  final String? category;
  final String? image;
  final String? description;

  Market({
    required this.id,
    required this.question,
    required this.outcomes,
    required this.prices,
    required this.volume,
    this.endDate,
    this.category,
    this.image,
    this.description,
  });

  double get yesPrice => prices.isNotEmpty ? prices[0] : 0.5;
  double get noPrice => prices.length > 1 ? prices[1] : 0.5;
  int get yesPct => (yesPrice * 100).round();
  int get noPct => (noPrice * 100).round();

  String get volumeFormatted {
    if (volume >= 1000000) return '\$${(volume / 1000000).toStringAsFixed(1)}M';
    if (volume >= 1000) return '\$${(volume / 1000).toStringAsFixed(0)}K';
    return '\$${volume.toStringAsFixed(0)}';
  }

  factory Market.fromJson(Map<String, dynamic> json) {
    // Outcomes
    List<String> outcomes = ['Yes', 'No'];
    if (json['outcomes'] != null) {
      try {
        outcomes = (jsonDecode(json['outcomes'] as String) as List).cast<String>();
      } catch (_) {}
    }

    // Prices
    List<double> prices = [0.5, 0.5];
    if (json['outcomePrices'] != null) {
      try {
        prices = (jsonDecode(json['outcomePrices'] as String) as List)
            .map((e) => double.tryParse(e.toString()) ?? 0.5)
            .toList();
      } catch (_) {}
    }

    // Volume
    double volume = double.tryParse(json['volume']?.toString() ?? '0') ?? 0;

    // End date
    DateTime? endDate;
    try { endDate = DateTime.parse(json['endDate'] ?? ''); } catch (_) {}

    // Image — prefer events image, then market image
    String? image = _extractImage(json);

    // Description — prefer events description
    String? description = _extractDescription(json);

    // Category — auto-detect from question + title
    final title = _extractTitle(json);
    final category = _detectCategory(json['question']?.toString() ?? '', title);

    return Market(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      outcomes: outcomes,
      prices: prices,
      volume: volume,
      endDate: endDate,
      category: category,
      image: image,
      description: description,
    );
  }

  static String? _extractImage(Map<String, dynamic> json) {
    // Try events.image first (best quality)
    final events = json['events'];
    if (events != null) {
      if (events is List && events.isNotEmpty) {
        final img = events[0]['image']?.toString();
        if (img != null && img.isNotEmpty) return img;
        final icon = events[0]['icon']?.toString();
        if (icon != null && icon.isNotEmpty) return icon;
      } else if (events is Map) {
        final img = events['image']?.toString();
        if (img != null && img.isNotEmpty) return img;
      }
    }
    // Fallback to market image
    final img = json['image']?.toString();
    if (img != null && img.isNotEmpty) return img;
    final icon = json['icon']?.toString();
    if (icon != null && icon.isNotEmpty) return icon;
    return null;
  }

  static String? _extractDescription(Map<String, dynamic> json) {
    final events = json['events'];
    if (events != null) {
      if (events is List && events.isNotEmpty) {
        final d = events[0]['description']?.toString();
        if (d != null && d.isNotEmpty) return d;
      } else if (events is Map) {
        final d = events['description']?.toString();
        if (d != null && d.isNotEmpty) return d;
      }
    }
    return json['description']?.toString();
  }

  static String? _extractTitle(Map<String, dynamic> json) {
    final events = json['events'];
    if (events is List && events.isNotEmpty) return events[0]['title']?.toString();
    if (events is Map) return events['title']?.toString();
    return null;
  }

  static String _detectCategory(String question, String? title) {
    final text = '${question.toLowerCase()} ${(title ?? '').toLowerCase()}';

    if (_match(text, ['election', 'president', 'senate', 'congress', 'trump', 'biden',
        'harris', 'democrat', 'republican', 'vote', 'poll', 'political', 'governor',
        'minister', 'parliament', 'chancellor', 'macron', 'zelensky', 'nato', 'sanction'])) {
      return 'Politics';
    }
    if (_match(text, ['bitcoin', 'btc', 'ethereum', 'eth', 'crypto', 'solana', 'sol',
        'doge', 'xrp', 'usdc', 'defi', 'nft', 'blockchain', 'coinbase', 'binance',
        'altcoin', 'token', 'memecoin', 'ondo', 'sui', 'avax'])) {
      return 'Crypto';
    }
    if (_match(text, ['nba', 'nfl', 'nhl', 'mlb', 'soccer', 'football', 'basketball',
        'tennis', 'golf', 'mma', 'ufc', 'champion', 'playoff', 'super bowl',
        'world cup', 'league', 'tournament', 'match', 'game', 'player', 'team',
        'score', 'win', 'draft'])) {
      return 'Sports';
    }
    if (_match(text, ['stock', 'nasdaq', 'sp500', 's&p', 'dow', 'fed', 'rate', 'gdp',
        'inflation', 'recession', 'earnings', 'ipo', 'market cap', 'tariff',
        'trade war', 'oil', 'gold', 'dollar', 'euro', 'yen', 'forex'])) {
      return 'Finance';
    }
    if (_match(text, ['ai', 'artificial intelligence', 'openai', 'gpt', 'llm', 'spacex',
        'nasa', 'rocket', 'satellite', 'climate', 'vaccine', 'cancer', 'drug',
        'fda', 'science', 'research', 'quantum', 'robot'])) {
      return 'Science';
    }
    if (_match(text, ['oscar', 'grammy', 'emmy', 'movie', 'film', 'album', 'artist',
        'singer', 'actor', 'celebrity', 'tv show', 'netflix', 'spotify', 'music',
        'box office', 'streaming'])) {
      return 'Entertainment';
    }
    if (_match(text, ['up or down', 'price', 'higher', 'lower', 'close', 'trading',
        'shares', 'equity', 'etf', 'index'])) {
      return 'Finance';
    }
    return 'World';
  }

  static bool _match(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}
