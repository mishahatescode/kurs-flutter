import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency_pair.dart';
import '../models/rate_source.dart';
import 'storage.dart';

/// Everything that survives a relaunch.
///
/// Call [load] once at startup so the rest of the API can be synchronous —
/// state restoration should not make the first frame wait on disk.
class PersistenceService implements ConverterStorage {
  PersistenceService._(this._prefs);

  static Future<PersistenceService> load() async =>
      PersistenceService._(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const _pinned = 'kurs.pinnedCurrencies';
  static const _recentPairs = 'kurs.recentPairs';
  static const _recents = 'kurs.recents';
  static const _cachedRates = 'kurs.rates';
  static const _cacheDate = 'kurs.cacheDate';
  static const _rateSource = 'kurs.rateSource';
  static const _bankMarkup = 'kurs.bankMarkup';
  static const _offline = 'kurs.offline';
  static const _numberLocale = 'kurs.numberLocale';
  static const _provider = 'kurs.provider';
  static const _darkMode = 'kurs.darkMode';
  static const _sourceCurrency = 'kurs.sourceCurrency';
  static const _targetCurrency = 'kurs.targetCurrency';

  @override
  List<String> get pinned => _prefs.getStringList(_pinned) ?? const [];
  @override
  Future<void> savePinned(List<String> codes) =>
      _prefs.setStringList(_pinned, codes);

  @override
  List<String> get recents => _prefs.getStringList(_recents) ?? const [];
  @override
  Future<void> saveRecents(List<String> codes) =>
      _prefs.setStringList(_recents, codes);

  @override
  List<CurrencyPair> get recentPairs {
    final raw = _prefs.getString(_recentPairs);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => CurrencyPair.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or from an older shape — drop it rather than fail to launch.
      return const [];
    }
  }

  @override
  Future<void> saveRecentPairs(List<CurrencyPair> pairs) => _prefs.setString(
    _recentPairs,
    jsonEncode(pairs.map((p) => p.toJson()).toList()),
  );

  @override
  ({Map<String, double> rates, DateTime date})? get cachedRates {
    final raw = _prefs.getString(_cachedRates);
    final millis = _prefs.getInt(_cacheDate);
    if (raw == null || millis == null) return null;
    try {
      final decoded = (jsonDecode(raw) as Map).cast<String, dynamic>();
      final rates = <String, double>{};
      decoded.forEach((k, v) {
        if (v is num) rates[k] = v.toDouble();
      });
      if (rates.isEmpty) return null;
      return (rates: rates, date: DateTime.fromMillisecondsSinceEpoch(millis));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRates(Map<String, double> rates, DateTime date) async {
    await _prefs.setString(_cachedRates, jsonEncode(rates));
    await _prefs.setInt(_cacheDate, date.millisecondsSinceEpoch);
  }

  @override
  RateSource? get rateSource =>
      RateSource.fromStorageKey(_prefs.getString(_rateSource));
  @override
  Future<void> saveRateSource(RateSource s) =>
      _prefs.setString(_rateSource, s.storageKey);

  /// Absent reads as the 2.5% default rather than 0 — a 0% "card" rate is
  /// indistinguishable from the market rate and looks like a broken setting.
  @override
  double get bankMarkup => _prefs.getDouble(_bankMarkup) ?? 2.5;
  @override
  Future<void> saveBankMarkup(double v) => _prefs.setDouble(_bankMarkup, v);

  @override
  bool get offline => _prefs.getBool(_offline) ?? false;
  @override
  Future<void> saveOffline(bool v) => _prefs.setBool(_offline, v);

  @override
  String? get numberLocale => _prefs.getString(_numberLocale);
  @override
  Future<void> saveNumberLocale(String id) =>
      _prefs.setString(_numberLocale, id);

  @override
  String? get provider => _prefs.getString(_provider);
  @override
  Future<void> saveProvider(String id) => _prefs.setString(_provider, id);

  /// `null` means follow the system, which is distinct from an explicit
  /// light choice — so absence, not `false`, carries that meaning.
  @override
  bool? get darkMode => _prefs.getBool(_darkMode);
  @override
  Future<void> saveDarkMode(bool? v) async {
    if (v == null) {
      await _prefs.remove(_darkMode);
    } else {
      await _prefs.setBool(_darkMode, v);
    }
  }

  @override
  String? get sourceCurrency => _prefs.getString(_sourceCurrency);
  @override
  Future<void> saveSourceCurrency(String code) =>
      _prefs.setString(_sourceCurrency, code);

  @override
  String? get targetCurrency => _prefs.getString(_targetCurrency);
  @override
  Future<void> saveTargetCurrency(String code) =>
      _prefs.setString(_targetCurrency, code);
}
