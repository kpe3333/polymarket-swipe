import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum LangMode { english, manual, byIp }

class TranslationService {
  static final TranslationService _i = TranslationService._();
  factory TranslationService() => _i;
  TranslationService._();

  // Settings
  LangMode mode = LangMode.english;
  String primaryLang = 'en';   // main language
  String? secondaryLang;       // optional second language shown below
  String? _detectedLang;       // auto-detected by IP

  final Map<String, String> _cache = {};

  static const _langNames = {
    'en': 'English',
    'ru': 'Russian',
    'de': 'German',
    'fr': 'French',
    'es': 'Spanish',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'pt': 'Portuguese',
    'tr': 'Turkish',
    'uk': 'Ukrainian',
  };

  static Map<String, String> get availableLanguages => _langNames;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    mode = LangMode.values[p.getInt('lang_mode') ?? 0];
    primaryLang = p.getString('lang_primary') ?? 'en';
    secondaryLang = p.getString('lang_secondary');
    // Load cache
    final raw = p.getString('translation_cache');
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _cache.addAll(map.cast<String, String>());
    }
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('lang_mode', mode.index);
    await p.setString('lang_primary', primaryLang);
    if (secondaryLang != null) {
      await p.setString('lang_secondary', secondaryLang!);
    } else {
      await p.remove('lang_secondary');
    }
  }

  Future<void> detectByIp() async {
    try {
      final r = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        final countryCode = (json['country_code'] as String?)?.toLowerCase();
        _detectedLang = _countryToLang(countryCode);
      }
    } catch (_) {
      _detectedLang = 'en';
    }
  }

  String get activePrimaryLang {
    if (mode == LangMode.byIp) return _detectedLang ?? 'en';
    return primaryLang;
  }

  bool get needsTranslation => activePrimaryLang != 'en';
  bool get hasSecondary => mode == LangMode.manual && secondaryLang != null && secondaryLang != 'en';

  /// Translate text to target language. Returns null if English or error.
  Future<String?> translate(String text, String targetLang) async {
    if (targetLang == 'en' || text.isEmpty) return null;
    final key = '$targetLang:${text.hashCode}';
    if (_cache.containsKey(key)) return _cache[key];

    try {
      // Use MyMemory free API (no key needed, 5000 words/day)
      final encoded = Uri.encodeComponent(text);
      final url = 'https://api.mymemory.translated.net/get?q=$encoded&langpair=en|$targetLang';
      final r = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        final json = jsonDecode(r.body);
        final translated = json['responseData']?['translatedText'] as String?;
        if (translated != null && translated.isNotEmpty && translated != text) {
          _cache[key] = translated;
          _persistCache();
          return translated;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _persistCache() async {
    if (_cache.length > 500) {
      // Keep only last 500 entries
      final entries = _cache.entries.toList();
      _cache.clear();
      _cache.addAll(Map.fromEntries(entries.skip(entries.length - 500)));
    }
    final p = await SharedPreferences.getInstance();
    await p.setString('translation_cache', jsonEncode(_cache));
  }

  String _countryToLang(String? code) {
    const map = {
      'ru': 'ru', 'by': 'ru', 'kz': 'ru', 'ua': 'uk',
      'de': 'de', 'at': 'de', 'ch': 'de',
      'fr': 'fr', 'be': 'fr',
      'es': 'es', 'mx': 'es', 'ar': 'es', 'co': 'es',
      'cn': 'zh', 'tw': 'zh',
      'jp': 'ja', 'kr': 'ko',
      'sa': 'ar', 'ae': 'ar', 'eg': 'ar',
      'br': 'pt', 'pt': 'pt',
      'tr': 'tr',
    };
    return map[code] ?? 'en';
  }
}
