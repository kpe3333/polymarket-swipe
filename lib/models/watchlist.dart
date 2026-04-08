import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'market.dart';

class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore _i = WatchlistStore._();
  factory WatchlistStore() => _i;
  WatchlistStore._();

  List<Market> _markets = [];
  List<Market> get markets => List.unmodifiable(_markets);

  bool isWatched(String id) => _markets.any((m) => m.id == id);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('watchlist') ?? [];
    try {
      _markets = raw.map((s) => Market.fromJson(jsonDecode(s))).toList();
    } catch (_) {
      _markets = [];
    }
  }

  Future<void> toggle(Market market) async {
    final idx = _markets.indexWhere((m) => m.id == market.id);
    if (idx >= 0) {
      _markets.removeAt(idx);
    } else {
      _markets.insert(0, market);
    }
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _markets.removeWhere((m) => m.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('watchlist', _markets.map((m) => jsonEncode(m.toJson())).toList());
  }
}
