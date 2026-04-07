import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market.dart';

class PolymarketService {
  static const _base = 'https://gamma-api.polymarket.com';

  Future<List<Market>> fetchMarkets({int limit = 30}) async {
    final uri = Uri.parse('$_base/markets').replace(queryParameters: {
      'limit': limit.toString(),
      'active': 'true',
      'closed': 'false',
      'order': 'volume',
      'ascending': 'false',
    });

    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Polymarket API error: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => Market.fromJson(e as Map<String, dynamic>))
        .where((m) => m.question.isNotEmpty)
        .toList();
  }
}
