import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BetStatus { open, won, lost }

class Bet {
  final String id;
  final String marketId;
  final String question;
  final String outcome;
  final double amount;
  final double price; // price at time of bet (0.0-1.0)
  final DateTime placedAt;
  final DateTime? resolvedAt;
  final BetStatus status;
  final String? image;
  final String? category;

  Bet({
    required this.id,
    required this.marketId,
    required this.question,
    required this.outcome,
    required this.amount,
    required this.price,
    required this.placedAt,
    this.resolvedAt,
    this.status = BetStatus.open,
    this.image,
    this.category,
  });

  double get potentialReturn => price > 0 ? amount / price : 0;
  double get pnl {
    if (status == BetStatus.won) return potentialReturn - amount;
    if (status == BetStatus.lost) return -amount;
    return 0;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'marketId': marketId,
    'question': question,
    'outcome': outcome,
    'amount': amount,
    'price': price,
    'placedAt': placedAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'status': status.index,
    'image': image,
    'category': category,
  };

  factory Bet.fromJson(Map<String, dynamic> j) => Bet(
    id: j['id'],
    marketId: j['marketId'],
    question: j['question'],
    outcome: j['outcome'],
    amount: (j['amount'] as num).toDouble(),
    price: (j['price'] as num).toDouble(),
    placedAt: DateTime.parse(j['placedAt']),
    resolvedAt: j['resolvedAt'] != null ? DateTime.parse(j['resolvedAt']) : null,
    status: BetStatus.values[j['status'] ?? 0],
    image: j['image'],
    category: j['category'],
  );
}

class BetStore extends ChangeNotifier {
  static final BetStore _i = BetStore._();
  factory BetStore() => _i;
  BetStore._();

  List<Bet> _bets = [];
  List<Bet> get bets => List.unmodifiable(_bets);

  List<Bet> get open => _bets.where((b) => b.status == BetStatus.open).toList();
  List<Bet> get resolved => _bets.where((b) => b.status != BetStatus.open).toList();

  double get totalInvested => open.fold(0, (s, b) => s + b.amount);
  double get totalPotential => open.fold(0, (s, b) => s + b.potentialReturn);
  double get realizedPnL => resolved.fold(0, (s, b) => s + b.pnl);
  int get wins => _bets.where((b) => b.status == BetStatus.won).length;
  int get losses => _bets.where((b) => b.status == BetStatus.lost).length;
  double get winRate => (wins + losses) > 0 ? wins / (wins + losses) : 0;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('bets') ?? [];
    _bets = raw.map((s) => Bet.fromJson(jsonDecode(s))).toList();
    _bets.sort((a, b) => b.placedAt.compareTo(a.placedAt));
  }

  Future<void> addBet(Bet bet) async {
    _bets.insert(0, bet);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('bets', _bets.map((b) => jsonEncode(b.toJson())).toList());
  }

  // For demo: simulate random resolution of old open bets
  Future<void> simulateResolution() async {
    bool changed = false;
    _bets = _bets.map((b) {
      if (b.status == BetStatus.open &&
          DateTime.now().difference(b.placedAt).inMinutes > 1) {
        final won = (b.id.hashCode % 2) == 0;
        changed = true;
        return Bet(
          id: b.id,
          marketId: b.marketId,
          question: b.question,
          outcome: b.outcome,
          amount: b.amount,
          price: b.price,
          placedAt: b.placedAt,
          resolvedAt: DateTime.now(),
          status: won ? BetStatus.won : BetStatus.lost,
          image: b.image,
          category: b.category,
        );
      }
      return b;
    }).toList();
    if (changed) {
      await _save();
      notifyListeners();
    }
  }
}
