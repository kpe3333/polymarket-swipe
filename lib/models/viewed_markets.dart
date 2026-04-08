import 'package:shared_preferences/shared_preferences.dart';

class ViewedStore {
  static final ViewedStore _i = ViewedStore._();
  factory ViewedStore() => _i;
  ViewedStore._();

  Set<String> _viewed = {};

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _viewed = Set.from(p.getStringList('viewed_markets') ?? []);
  }

  bool isViewed(String id) => _viewed.contains(id);

  Future<void> markViewed(String id) async {
    if (_viewed.contains(id)) return;
    _viewed.add(id);
    if (_viewed.length > 2000) {
      _viewed = _viewed.skip(_viewed.length - 2000).toSet();
    }
    final p = await SharedPreferences.getInstance();
    await p.setStringList('viewed_markets', _viewed.toList());
  }

  Future<void> clear() async {
    _viewed.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('viewed_markets');
  }

  int get count => _viewed.length;
}
