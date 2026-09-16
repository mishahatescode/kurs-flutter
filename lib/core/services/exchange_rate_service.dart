import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/rate_provider.dart';

/// Thrown when a feed cannot be reached or returns something unusable.
class RateFetchException implements Exception {
  RateFetchException(this.message);
  final String message;
  @override
  String toString() => 'RateFetchException: $message';
}

/// Fetches USD-relative rates. An interface so tests can supply a fake
/// without touching the network — see `test/core/`.
abstract interface class ExchangeRateService {
  Future<Map<String, double>> fetchRates(RateProvider provider);
}

class HttpExchangeRateService implements ExchangeRateService {
  HttpExchangeRateService({http.Client? client, this.timeout = _defaultTimeout})
    : _client = client ?? http.Client();

  static const _defaultTimeout = Duration(milliseconds: 4500);

  final http.Client _client;
  final Duration timeout;

  @override
  Future<Map<String, double>> fetchRates(RateProvider provider) async {
    final rates = switch (provider) {
      RateProvider.frankfurter => await _fetchFrankfurter(),
      RateProvider.openERAPI => await _fetchOpenER(),
      RateProvider.fawazCurrencyAPI => await _fetchFawaz(),
    };
    if (rates.isEmpty) {
      throw RateFetchException('${provider.displayName} returned no rates');
    }
    return rates;
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(url)).timeout(timeout);
    } on TimeoutException {
      throw RateFetchException('$url timed out');
    } catch (e) {
      throw RateFetchException('$url unreachable: $e');
    }
    if (response.statusCode != 200) {
      throw RateFetchException('$url returned HTTP ${response.statusCode}');
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw RateFetchException('$url returned unparseable JSON');
    }
  }

  /// Rate maps arrive with mixed int/double JSON numbers, so coerce rather
  /// than casting — a whole-number rate decodes as int and a blind cast to
  /// double throws.
  Map<String, double> _coerce(Map<String, dynamic> raw, {bool upper = false}) {
    final out = <String, double>{};
    raw.forEach((key, value) {
      if (value is num) out[upper ? key.toUpperCase() : key] = value.toDouble();
    });
    return out;
  }

  // ECB reference rates, via Frankfurter.
  Future<Map<String, double>> _fetchFrankfurter() async {
    final json = await _getJson('https://api.frankfurter.app/latest?from=USD');
    final rates = _coerce(
      (json['rates'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    // The base currency is not included in its own rate table.
    rates['USD'] = 1.0;
    return rates;
  }

  // open.er-api.com — mid-market aggregate.
  Future<Map<String, double>> _fetchOpenER() async {
    final json = await _getJson('https://open.er-api.com/v6/latest/USD');
    if (json['result'] != 'success') {
      throw RateFetchException('open.er-api.com reported ${json['result']}');
    }
    return _coerce((json['rates'] as Map?)?.cast<String, dynamic>() ?? {});
  }

  // Fawaz Ahmed's currency-api — community, CDN-hosted, no key. Lowercase
  // codes, so they are upcased to match the rest of the app.
  Future<Map<String, double>> _fetchFawaz() async {
    final json = await _getJson(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest'
      '/v1/currencies/usd.json',
    );
    final rates = _coerce(
      (json['usd'] as Map?)?.cast<String, dynamic>() ?? {},
      upper: true,
    );
    rates['USD'] = 1.0;
    return rates;
  }
}
