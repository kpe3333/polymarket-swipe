import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static final AppSettings _instance = AppSettings._();
  factory AppSettings() => _instance;
  AppSettings._();

  // Ставка
  double _defaultBet = 10.0;
  double get defaultBet => _defaultBet;

  // Тема
  bool _darkMode = true;
  bool get darkMode => _darkMode;

  // Категории
  Set<String> _selectedCategories = {};
  Set<String> get selectedCategories => _selectedCategories;

  // Кошелёк
  String _walletAddress = '';
  String get walletAddress => _walletAddress;

  String _apiKey = '';
  String get apiKey => _apiKey;

  // Фильтры
  double _minVolume = 0;
  double get minVolume => _minVolume;

  int _maxDaysLeft = 0; // 0 = без ограничений
  int get maxDaysLeft => _maxDaysLeft;

  static const _keyBet = 'default_bet';
  static const _keyDark = 'dark_mode';
  static const _keyCategories = 'categories';
  static const _keyWallet = 'wallet_address';
  static const _keyApiKey = 'api_key';
  static const _keyMinVolume = 'min_volume';
  static const _keyMaxDays = 'max_days';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _defaultBet = p.getDouble(_keyBet) ?? 10.0;
    _darkMode = p.getBool(_keyDark) ?? true;
    _walletAddress = p.getString(_keyWallet) ?? '';
    _apiKey = p.getString(_keyApiKey) ?? '';
    _minVolume = p.getDouble(_keyMinVolume) ?? 0;
    _maxDaysLeft = p.getInt(_keyMaxDays) ?? 0;
    final cats = p.getStringList(_keyCategories);
    _selectedCategories = cats != null ? Set.from(cats) : {};
    notifyListeners();
  }

  Future<void> setDefaultBet(double v) async {
    _defaultBet = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyBet, v);
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyDark, v);
    notifyListeners();
  }

  Future<void> setWalletAddress(String v) async {
    _walletAddress = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyWallet, v);
    notifyListeners();
  }

  Future<void> setApiKey(String v) async {
    _apiKey = v;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyApiKey, v);
    notifyListeners();
  }

  Future<void> setMinVolume(double v) async {
    _minVolume = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_keyMinVolume, v);
    notifyListeners();
  }

  Future<void> setMaxDaysLeft(int v) async {
    _maxDaysLeft = v;
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyMaxDays, v);
    notifyListeners();
  }

  Future<void> toggleCategory(String cat) async {
    if (_selectedCategories.contains(cat)) {
      _selectedCategories.remove(cat);
    } else {
      _selectedCategories.add(cat);
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_keyCategories, _selectedCategories.toList());
    notifyListeners();
  }
}
