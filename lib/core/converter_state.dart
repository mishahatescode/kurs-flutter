import 'package:flutter/foundation.dart';

import 'conversion.dart';
import 'formatting.dart';
import 'models/currency.dart';
import 'models/currency_pair.dart';
import 'models/rate_provider.dart';
import 'models/rate_source.dart';
import 'services/exchange_rate_service.dart';
import 'services/storage.dart';

const int kMaxRecentPairs = 10;
const int kMaxRecentCurrencies = 8;

/// All converter state and the rules that move it.
///
/// Holds no widgets and no navigation flags — which sheet is open is the UI
/// layer's business, handled with routes. That keeps every rule below
/// reachable from a plain `flutter test` on any operating system.
class ConverterState extends ChangeNotifier {
  /// Positional rather than named because Dart forbids named parameters that
  /// start with an underscore, and these fields are private.
  ConverterState(this._storage, this._exchange) {
    _restore();
  }

  final ConverterStorage _storage;
  final ExchangeRateService _exchange;

  // ── Converter ──────────────────────────────────────────────────────────

  Currency _source = kCurrencyByCode['USD']!;
  Currency _target = kCurrencyByCode['EUR']!;

  /// The digits under the keypad, always canonical: `.` separator, no
  /// grouping. Locale separators are applied at display time only.
  String _buffer = '1';
  bool _isSourceActive = true;

  Currency get source => _source;
  Currency get target => _target;
  String get buffer => _buffer;
  bool get isSourceActive => _isSourceActive;

  /// The currency the keypad is currently editing.
  Currency get activeCurrency => _isSourceActive ? _source : _target;

  /// The value typed into the active row.
  double get activeAmount => parseAmount(_buffer);

  double get rate => conversionRate(
    from: _source,
    to: _target,
    rates: _rates,
    source: _rateSource,
    bankMarkup: _bankMarkup,
  );

  double get sourceValue {
    if (_isSourceActive) return activeAmount;
    final r = rate;
    return r > 0 ? activeAmount / r : 0;
  }

  double get targetValue =>
      _isSourceActive ? activeAmount * rate : activeAmount;

  // ── Lists ──────────────────────────────────────────────────────────────

  List<String> _pinned = [];
  List<CurrencyPair> _recentPairs = [];
  List<String> _recentCurrencies = [];

  List<String> get pinned => List.unmodifiable(_pinned);
  List<CurrencyPair> get recentPairs => List.unmodifiable(_recentPairs);
  List<String> get recentCurrencies => List.unmodifiable(_recentCurrencies);

  // ── Rate data ──────────────────────────────────────────────────────────

  Map<String, double> _rates = {};
  bool _isLoading = false;
  DateTime? _lastUpdated;
  String? _loadError;
  bool _isOffline = false;

  Map<String, double> get rates => Map.unmodifiable(_rates);
  bool get isLoading => _isLoading;
  DateTime? get lastUpdated => _lastUpdated;
  String? get loadError => _loadError;
  bool get isOffline => _isOffline;
  bool get isStale => _loadError != null;

  /// True only for the very first fetch after launch — a background refresh
  /// already has numbers on screen and does not need as loud a signal.
  bool get isInitialLoad => _isLoading && _lastUpdated == null;

  int? get supportedCount =>
      _rates.isEmpty ? null : supportedCurrencyCount(_rates);

  // ── Settings ───────────────────────────────────────────────────────────

  RateSource _rateSource = RateSource.market;
  double _bankMarkup = 2.5;
  String _numberLocaleId = 'en_US';
  RateProvider _provider = RateProvider.openERAPI;
  bool? _isDarkMode;

  RateSource get rateSource => _rateSource;
  double get bankMarkup => _bankMarkup;
  String get numberLocaleId => _numberLocaleId;
  RateProvider get provider => _provider;
  bool? get isDarkMode => _isDarkMode;

  // ── Display strings ────────────────────────────────────────────────────

  String get sourceDisplay => _isSourceActive
      ? formatInputForDisplay(_buffer, localeId: _numberLocaleId)
      : formatAmount(
          sourceValue,
          decimalPlaces: _source.decimalPlaces,
          localeId: _numberLocaleId,
        );

  String get targetDisplay => _isSourceActive
      ? formatAmount(
          targetValue,
          decimalPlaces: _target.decimalPlaces,
          localeId: _numberLocaleId,
        )
      : formatInputForDisplay(_buffer, localeId: _numberLocaleId);

  String get rateInfo {
    final formatted = formatAmount(
      rate,
      decimalPlaces: _target.decimalPlaces,
      localeId: _numberLocaleId,
    );
    final label = _rateSource == RateSource.market
        ? _provider.displayName
        : 'Card or bank';
    return '1 ${_source.code} = $formatted ${_target.code} · $label';
  }

  String updatedAgo({DateTime? now}) => updatedAgoText(_lastUpdated, now: now);

  double rateFor(Currency from, Currency to) => conversionRate(
    from: from,
    to: to,
    rates: _rates,
    source: _rateSource,
    bankMarkup: _bankMarkup,
  );

  String format(double value, Currency currency) => formatAmount(
    value,
    decimalPlaces: currency.decimalPlaces,
    localeId: _numberLocaleId,
  );

  // ── Keypad ─────────────────────────────────────────────────────────────

  void keypadTap(String key) {
    final maxDecimals = activeCurrency.decimalPlaces;

    switch (key) {
      case 'back':
        _buffer = _buffer.length > 1
            ? _buffer.substring(0, _buffer.length - 1)
            : '0';
      case 'decimal':
        if (maxDecimals == 0 || _buffer.contains('.')) return;
        _buffer += '.';
      default:
        final dot = _buffer.indexOf('.');
        if (dot >= 0 && _buffer.length - dot - 1 >= maxDecimals) return;
        _buffer = _buffer == '0' ? key : _buffer + key;
    }
    _persistPair();
    notifyListeners();
  }

  void clearAmount() {
    _buffer = '0';
    notifyListeners();
  }

  /// Moves the keypad to the other row, re-seeding the buffer from what that
  /// row is currently showing so editing continues from the visible number.
  void setActiveRow({required bool source}) {
    if (_isSourceActive == source) return;
    final value = source ? sourceValue : targetValue;
    final currency = source ? _source : _target;
    _buffer = formatAmountRaw(value, decimalPlaces: currency.decimalPlaces);
    _isSourceActive = source;
    notifyListeners();
  }

  // ── Currencies ─────────────────────────────────────────────────────────

  void selectCurrency(Currency currency, {required bool forSource}) {
    if (forSource) {
      _source = currency;
    } else {
      _target = currency;
    }
    // A currency with fewer decimals cannot display what is already typed —
    // 1.25 makes no sense in yen — so trim the buffer to fit.
    _truncateBufferToActiveCurrency();
    recordRecentCurrency(currency.code);
    recordCurrentPair();
    _persistPair();
    notifyListeners();
  }

  void _truncateBufferToActiveCurrency() {
    final maxDecimals = activeCurrency.decimalPlaces;
    final dot = _buffer.indexOf('.');
    if (dot < 0) return;
    if (maxDecimals == 0) {
      _buffer = _buffer.substring(0, dot);
    } else if (_buffer.length - dot - 1 > maxDecimals) {
      _buffer = _buffer.substring(0, dot + 1 + maxDecimals);
    }
    if (_buffer.isEmpty) _buffer = '0';
  }

  /// Swaps the two rows, carrying their values with them — the amount showing
  /// on the target becomes the new source amount, rather than the typed
  /// digits being reinterpreted under a different currency.
  void swapCurrencies() {
    final newSourceValue = targetValue;
    final oldSource = _source;
    _source = _target;
    _target = oldSource;
    _buffer = formatAmountRaw(
      newSourceValue,
      decimalPlaces: _source.decimalPlaces,
    );
    _isSourceActive = true;
    recordCurrentPair();
    _persistPair();
    notifyListeners();
  }

  void applyPair(CurrencyPair pair) {
    final from = kCurrencyByCode[pair.from];
    final to = kCurrencyByCode[pair.to];
    if (from == null || to == null) return;
    _source = from;
    _target = to;
    _isSourceActive = true;
    _truncateBufferToActiveCurrency();
    recordCurrentPair();
    _persistPair();
    notifyListeners();
  }

  // ── Pins ───────────────────────────────────────────────────────────────

  bool isPinned(String code) => _pinned.contains(code);

  void togglePin(String code) {
    _pinned.contains(code) ? _pinned.remove(code) : _pinned.add(code);
    _storage.savePinned(_pinned);
    notifyListeners();
  }

  void clearPinned() {
    _pinned = [];
    _storage.savePinned(_pinned);
    notifyListeners();
  }

  // ── Recents ────────────────────────────────────────────────────────────

  /// Puts the active pair at the front of the recents, capped at
  /// [kMaxRecentPairs]. A same-currency pair is always 1:1 and tells the user
  /// nothing, so it is never recorded.
  void recordCurrentPair() {
    if (_source.code == _target.code) return;
    final pair = CurrencyPair(_source.code, _target.code);
    _recentPairs
      ..remove(pair)
      ..insert(0, pair);
    if (_recentPairs.length > kMaxRecentPairs) {
      _recentPairs = _recentPairs.sublist(0, kMaxRecentPairs);
    }
    _storage.saveRecentPairs(_recentPairs);
  }

  void removeRecentPair(CurrencyPair pair) {
    _recentPairs.remove(pair);
    _storage.saveRecentPairs(_recentPairs);
    notifyListeners();
  }

  void clearRecentPairs() {
    _recentPairs = [];
    _storage.saveRecentPairs(_recentPairs);
    notifyListeners();
  }

  void recordRecentCurrency(String code) {
    _recentCurrencies
      ..remove(code)
      ..insert(0, code);
    if (_recentCurrencies.length > kMaxRecentCurrencies) {
      _recentCurrencies = _recentCurrencies.sublist(0, kMaxRecentCurrencies);
    }
    _storage.saveRecents(_recentCurrencies);
  }

  void clearRecentCurrencies() {
    _recentCurrencies = [];
    _storage.saveRecents(_recentCurrencies);
    notifyListeners();
  }

  // ── Rates ──────────────────────────────────────────────────────────────

  Future<void> refreshRates() async {
    if (_isOffline) {
      // Offline Mode simulates no connectivity without touching the network,
      // but still raises the same stale signal a real failure would, so the
      // UI has one code path to render.
      _loadError = 'Offline — showing cached rates';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final fetched = await _exchange.fetchRates(_provider);
      _rates = fetched;
      _lastUpdated = DateTime.now();
      _loadError = null;
      await _storage.saveRates(fetched, _lastUpdated!);
    } catch (_) {
      final cached = _storage.cachedRates;
      if (cached != null) {
        _rates = cached.rates;
        _lastUpdated = cached.date;
        _loadError = 'No connection — showing cached rates';
      } else {
        _loadError = 'No connection — using built-in fallback rates';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Has to change what is on screen straight away. The stale signal is
  /// driven by [loadError], which otherwise would not be set until the next
  /// refresh attempt — leaving the toggle looking inert.
  void setOffline(bool offline) {
    _isOffline = offline;
    _storage.saveOffline(offline);
    if (offline) {
      _isLoading = false;
      _loadError = 'Offline — showing cached rates';
      notifyListeners();
    } else {
      _loadError = null;
      notifyListeners();
      refreshRates();
    }
  }

  // ── Setting mutations ──────────────────────────────────────────────────

  void setRateSource(RateSource s) {
    _rateSource = s;
    _storage.saveRateSource(s);
    notifyListeners();
  }

  void setBankMarkup(double v) {
    _bankMarkup = v;
    _storage.saveBankMarkup(v);
    notifyListeners();
  }

  void setNumberLocale(String id) {
    _numberLocaleId = id;
    _storage.saveNumberLocale(id);
    notifyListeners();
  }

  void setDarkMode(bool? v) {
    _isDarkMode = v;
    _storage.saveDarkMode(v);
    notifyListeners();
  }

  /// Returns true if the feed actually changed, so the caller can refresh.
  bool setProvider(RateProvider p) {
    if (_provider == p) return false;
    _provider = p;
    _storage.saveProvider(p.storageKey);
    notifyListeners();
    return true;
  }

  // ── Persistence ────────────────────────────────────────────────────────

  void _persistPair() {
    _storage.saveSourceCurrency(_source.code);
    _storage.saveTargetCurrency(_target.code);
  }

  void _restore() {
    _pinned = [..._storage.pinned];
    _recentPairs = [..._storage.recentPairs];
    _recentCurrencies = [..._storage.recents];

    final cached = _storage.cachedRates;
    if (cached != null) {
      _rates = cached.rates;
      _lastUpdated = cached.date;
    }

    _rateSource = _storage.rateSource ?? _rateSource;
    _bankMarkup = _storage.bankMarkup;
    _isOffline = _storage.offline;
    _numberLocaleId = _storage.numberLocale ?? _numberLocaleId;
    _provider = RateProvider.fromStorageKey(_storage.provider) ?? _provider;
    _isDarkMode = _storage.darkMode;
    _source = kCurrencyByCode[_storage.sourceCurrency] ?? _source;
    _target = kCurrencyByCode[_storage.targetCurrency] ?? _target;
  }
}
