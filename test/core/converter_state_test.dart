import 'package:flutter_test/flutter_test.dart';
import 'package:kurs/core/converter_state.dart';
import 'package:kurs/core/models/currency.dart';
import 'package:kurs/core/models/currency_pair.dart';
import 'package:kurs/core/models/rate_provider.dart';
import 'package:kurs/core/services/exchange_rate_service.dart';
import 'package:kurs/core/services/storage.dart';

class _FakeExchange implements ExchangeRateService {
  _FakeExchange({this.rates, this.error});

  final Map<String, double>? rates;
  final Object? error;
  int calls = 0;

  @override
  Future<Map<String, double>> fetchRates(RateProvider provider) async {
    calls++;
    if (error != null) throw error!;
    return rates!;
  }
}

void main() {
  final usd = kCurrencyByCode['USD']!;
  final eur = kCurrencyByCode['EUR']!;
  final jpy = kCurrencyByCode['JPY']!;
  final kwd = kCurrencyByCode['KWD']!; // 3 decimals

  /// USD→EUR is exactly 0.5, which keeps the arithmetic in these tests
  /// checkable by eye.
  ConverterState build({InMemoryStorage? storage, _FakeExchange? exchange}) {
    final s = storage ?? InMemoryStorage();
    s.cachedRates = (rates: {'USD': 1.0, 'EUR': 0.5}, date: DateTime(2026));
    return ConverterState(s, exchange ?? _FakeExchange(rates: const {}));
  }

  group('keypad', () {
    test('the first digit replaces the leading zero', () {
      final s = build()..clearAmount();
      s.keypadTap('7');
      expect(s.buffer, '7');
      s.keypadTap('5');
      expect(s.buffer, '75');
    });

    test('backspace deletes a digit, then bottoms out at zero', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('2');
      s.keypadTap('back');
      expect(s.buffer, '1');
      s.keypadTap('back');
      expect(s.buffer, '0');
      s.keypadTap('back');
      expect(s.buffer, '0');
    });

    test('accepts only one decimal point', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('decimal')
        ..keypadTap('decimal');
      expect(s.buffer, '1.');
    });

    test('stops at the currency decimal limit', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('decimal')
        ..keypadTap('2')
        ..keypadTap('3');
      expect(s.buffer, '1.23');
      s.keypadTap('4'); // USD allows 2
      expect(s.buffer, '1.23');
    });

    test('a zero-decimal currency refuses the decimal key entirely', () {
      final s = build()..selectCurrency(jpy, forSource: true);
      s.clearAmount();
      s
        ..keypadTap('5')
        ..keypadTap('decimal')
        ..keypadTap('1');
      expect(s.buffer, '51', reason: 'the decimal should never be inserted');
    });

    test('a three-decimal currency allows all three', () {
      final s = build()..selectCurrency(kwd, forSource: true);
      s.clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('decimal')
        ..keypadTap('2')
        ..keypadTap('3')
        ..keypadTap('4');
      expect(s.buffer, '1.234');
    });
  });

  group('editing the target row', () {
    // Regression: the SwiftUI build converted the target amount back into a
    // source amount after *every* keystroke and flipped focus to the source
    // row, so only the first digit typed on the target ever landed.
    test('keeps focus on the target while typing', () {
      final s = build();
      s.setActiveRow(source: false);
      expect(s.isSourceActive, isFalse);
      s.clearAmount();

      s
        ..keypadTap('5')
        ..keypadTap('0');
      expect(s.isSourceActive, isFalse, reason: 'focus must not jump back');
      expect(s.buffer, '50', reason: 'both digits land, not just the first');
    });

    test('drives the source row from the typed target value', () {
      final s = build();
      s.setActiveRow(source: false);
      s.clearAmount();
      s
        ..keypadTap('5')
        ..keypadTap('0');

      expect(s.targetValue, 50.0);
      expect(s.sourceValue, 100.0, reason: '50 EUR at 0.5 is 100 USD');
    });

    test('switching rows re-seeds the buffer from what that row shows', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('0')
        ..keypadTap('0');
      expect(s.targetValue, 50.0);

      s.setActiveRow(source: false);
      expect(
        s.buffer,
        '50',
        reason: 'editing continues from the visible number',
      );
    });
  });

  group('swap', () {
    test('carries the values across with the currencies', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('0')
        ..keypadTap('0');
      expect(s.targetValue, 50.0);

      s.swapCurrencies();

      expect(s.source, eur);
      expect(s.target, usd);
      expect(s.sourceValue, 50.0, reason: 'the target amount moved up a row');
      expect(
        s.targetValue,
        100.0,
        reason: 'and converts back to where it came from',
      );
      expect(s.isSourceActive, isTrue);
    });
  });

  group('changing currency', () {
    test('trims a buffer the new currency cannot display', () {
      final s = build()..clearAmount();
      s
        ..keypadTap('1')
        ..keypadTap('decimal')
        ..keypadTap('2')
        ..keypadTap('5');
      expect(s.buffer, '1.25');

      s.selectCurrency(jpy, forSource: true);
      expect(s.buffer, '1', reason: 'yen has no minor unit');
    });
  });

  group('recent pairs', () {
    test('most recent first, with no duplicates', () {
      final s = build();
      s.selectCurrency(jpy, forSource: false); // USD→JPY
      s.selectCurrency(eur, forSource: false); // USD→EUR
      s.selectCurrency(jpy, forSource: false); // USD→JPY again

      expect(s.recentPairs.first, const CurrencyPair('USD', 'JPY'));
      expect(s.recentPairs.where((p) => p.to == 'JPY').length, 1);
    });

    test('never records a currency against itself', () {
      final s = build();
      s.selectCurrency(usd, forSource: false); // USD→USD
      expect(s.recentPairs, isEmpty);
    });

    test('caps at ten', () {
      final s = build();
      for (final c in kCurrencies.take(12)) {
        if (c.code == 'USD') continue;
        s.selectCurrency(c, forSource: false);
      }
      expect(s.recentPairs.length, kMaxRecentPairs);
    });
  });

  group('pins', () {
    test('toggle on and off, and survive into storage', () {
      final storage = InMemoryStorage();
      final s = build(storage: storage);

      s.togglePin('EUR');
      expect(s.isPinned('EUR'), isTrue);
      expect(storage.pinned, ['EUR']);

      s.togglePin('EUR');
      expect(s.isPinned('EUR'), isFalse);
      expect(storage.pinned, isEmpty);
    });
  });

  group('refreshRates', () {
    test('a successful fetch replaces the rates and stamps the time', () async {
      final storage = InMemoryStorage();
      final s = build(
        storage: storage,
        exchange: _FakeExchange(rates: const {'USD': 1.0, 'EUR': 0.9}),
      );

      await s.refreshRates();

      expect(s.rates['EUR'], 0.9);
      expect(s.loadError, isNull);
      expect(s.isLoading, isFalse);
      expect(s.lastUpdated, isNotNull);
      expect(storage.cachedRates!.rates['EUR'], 0.9);
    });

    test('a failed fetch falls back to the cache and says so', () async {
      final storage = InMemoryStorage()
        ..cachedRates = (rates: {'USD': 1.0, 'EUR': 0.7}, date: DateTime(2026));
      final s = ConverterState(
        storage,
        _FakeExchange(error: Exception('down')),
      );

      await s.refreshRates();

      expect(s.rates['EUR'], 0.7);
      expect(s.loadError, contains('cached'));
      expect(s.isStale, isTrue);
      expect(s.isLoading, isFalse);
    });

    test('a failed fetch with no cache falls back to the seeds', () async {
      final s = ConverterState(
        InMemoryStorage(),
        _FakeExchange(error: Exception('down')),
      );

      await s.refreshRates();

      expect(s.loadError, contains('built-in'));
      // The converter still works — seed rates cover every currency.
      expect(s.rate, greaterThan(0));
    });

    test('offline mode never touches the network', () async {
      final exchange = _FakeExchange(rates: const {'USD': 1.0});
      final s = build(exchange: exchange)..setOffline(true);

      await s.refreshRates();

      expect(exchange.calls, 0);
      expect(s.isStale, isTrue, reason: 'still shows the stale signal');
    });
  });

  group('restore', () {
    test('reads the saved pair, settings and cache back', () {
      final storage = InMemoryStorage()
        ..sourceCurrency = 'JPY'
        ..targetCurrency = 'GBP'
        ..bankMarkup = 4.0
        ..numberLocale = 'de_DE'
        ..provider = RateProvider.frankfurter.storageKey
        ..darkMode = true
        ..pinned = ['EUR', 'CHF'];

      final s = ConverterState(storage, _FakeExchange(rates: const {}));

      expect(s.source.code, 'JPY');
      expect(s.target.code, 'GBP');
      expect(s.bankMarkup, 4.0);
      expect(s.numberLocaleId, 'de_DE');
      expect(s.provider, RateProvider.frankfurter);
      expect(s.isDarkMode, isTrue);
      expect(s.pinned, ['EUR', 'CHF']);
    });

    test('an unknown saved currency code falls back to the default', () {
      final storage = InMemoryStorage()..sourceCurrency = 'XXX';
      final s = ConverterState(storage, _FakeExchange(rates: const {}));
      expect(s.source.code, 'USD');
    });
  });
}
