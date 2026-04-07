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

  Market({
    required this.id,
    required this.question,
    required this.outcomes,
    required this.prices,
    required this.volume,
    this.endDate,
    this.category,
    this.image,
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
    List<String> outcomes = ['Yes', 'No'];
    if (json['outcomes'] != null) {
      try {
        final raw = json['outcomes'] as String;
        outcomes = (jsonDecode(raw) as List).cast<String>();
      } catch (_) {}
    }

    List<double> prices = [0.5, 0.5];
    if (json['outcomePrices'] != null) {
      try {
        final raw = json['outcomePrices'] as String;
        prices = (jsonDecode(raw) as List)
            .map((e) => double.tryParse(e.toString()) ?? 0.5)
            .toList();
      } catch (_) {}
    }

    double volume = 0;
    if (json['volume'] != null) {
      volume = double.tryParse(json['volume'].toString()) ?? 0;
    }

    DateTime? endDate;
    if (json['endDate'] != null) {
      try {
        endDate = DateTime.parse(json['endDate']);
      } catch (_) {}
    }

    return Market(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      outcomes: outcomes,
      prices: prices,
      volume: volume,
      endDate: endDate,
      category: json['category']?.toString(),
      image: json['image']?.toString(),
    );
  }
}
