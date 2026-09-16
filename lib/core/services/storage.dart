import '../models/currency_pair.dart';
import '../models/rate_source.dart';

/// Everything that survives a relaunch.
///
/// An interface, not a class, so [ConverterState] never depends on a platform
/// plugin. Tests use [InMemoryStorage] and run as plain Dart on any OS; the
/// app uses the `shared_preferences` implementation.
abstract interface class ConverterStorage {
  List<String> get pinned;
  Future<void> savePinned(List<String> codes);

  List<String> get recents;
  Future<void> saveRecents(List<String> codes);

  List<CurrencyPair> get recentPairs;
  Future<void> saveRecentPairs(List<CurrencyPair> pairs);

  ({Map<String, double> rates, DateTime date})? get cachedRates;
  Future<void> saveRates(Map<String, double> rates, DateTime date);

  RateSource? get rateSource;
  Future<void> saveRateSource(RateSource s);

  double get bankMarkup;
  Future<void> saveBankMarkup(double v);

  bool get offline;
  Future<void> saveOffline(bool v);

  String? get numberLocale;
  Future<void> saveNumberLocale(String id);

  String? get provider;
  Future<void> saveProvider(String id);

  bool? get darkMode;
  Future<void> saveDarkMode(bool? v);

  String? get sourceCurrency;
  Future<void> saveSourceCurrency(String code);

  String? get targetCurrency;
  Future<void> saveTargetCurrency(String code);
}

/// Non-persistent storage. Used by tests, and by any harness that wants the
/// app to start from a known blank state.
class InMemoryStorage implements ConverterStorage {
  @override
  List<String> pinned = [];
  @override
  Future<void> savePinned(List<String> codes) async => pinned = [...codes];

  @override
  List<String> recents = [];
  @override
  Future<void> saveRecents(List<String> codes) async => recents = [...codes];

  @override
  List<CurrencyPair> recentPairs = [];
  @override
  Future<void> saveRecentPairs(List<CurrencyPair> pairs) async =>
      recentPairs = [...pairs];

  @override
  ({Map<String, double> rates, DateTime date})? cachedRates;
  @override
  Future<void> saveRates(Map<String, double> rates, DateTime date) async =>
      cachedRates = (rates: {...rates}, date: date);

  @override
  RateSource? rateSource;
  @override
  Future<void> saveRateSource(RateSource s) async => rateSource = s;

  @override
  double bankMarkup = 2.5;
  @override
  Future<void> saveBankMarkup(double v) async => bankMarkup = v;

  @override
  bool offline = false;
  @override
  Future<void> saveOffline(bool v) async => offline = v;

  @override
  String? numberLocale;
  @override
  Future<void> saveNumberLocale(String id) async => numberLocale = id;

  @override
  String? provider;
  @override
  Future<void> saveProvider(String id) async => provider = id;

  @override
  bool? darkMode;
  @override
  Future<void> saveDarkMode(bool? v) async => darkMode = v;

  @override
  String? sourceCurrency;
  @override
  Future<void> saveSourceCurrency(String code) async => sourceCurrency = code;

  @override
  String? targetCurrency;
  @override
  Future<void> saveTargetCurrency(String code) async => targetCurrency = code;
}
