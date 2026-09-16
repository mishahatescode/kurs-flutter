import 'package:flutter_test/flutter_test.dart';
import 'package:kurs/core/conversion.dart';
import 'package:kurs/core/models/currency.dart';
import 'package:kurs/core/models/rate_source.dart';

void main() {
  final usd = kCurrencyByCode['USD']!;
  final eur = kCurrencyByCode['EUR']!;
  final jpy = kCurrencyByCode['JPY']!;

  double rate(
    Currency from,
    Currency to, {
    RateSource source = RateSource.market,
    double markup = 2.5,
    Map<String, double> rates = const {'USD': 1.0, 'EUR': 0.5},
  }) => conversionRate(
    from: from,
    to: to,
    rates: rates,
    source: source,
    bankMarkup: markup,
  );

  group('market rate', () {
    test('a currency against itself is exactly 1', () {
      expect(rate(usd, usd), 1.0);
      expect(rate(jpy, jpy, source: RateSource.card), 1.0);
    });

    test('is the ratio of the two USD-relative rates', () {
      expect(rate(usd, eur), 0.5);
      expect(rate(eur, usd), 2.0);
    });

    test('falls back to seed rates for a currency the feed omitted', () {
      // The ECB feed covers far fewer currencies than the picker offers.
      final r = rate(usd, jpy, rates: {'USD': 1.0, 'EUR': 0.5});
      expect(r, kSeedRates['JPY']);
    });

    test('a non-positive rate cannot produce infinity', () {
      expect(rate(usd, eur, rates: {'USD': 0.0, 'EUR': 0.5}), 1.0);
    });
  });

  group('card markup', () {
    // Regression: applying base * (1 + markup) to each leg independently made
    // a round trip *profitable*, because base is an exact reciprocal and the
    // two markups compounded into a net gain. A card must cost money in both
    // directions.
    test('a round trip loses money, never gains it', () {
      const markup = 2.5;
      final out = rate(usd, eur, source: RateSource.card, markup: markup);
      final back = rate(eur, usd, source: RateSource.card, markup: markup);

      final roundTrip = 100.0 * out * back;
      expect(
        roundTrip,
        lessThan(100.0),
        reason: 'converting there and back must not create money',
      );
      // Roughly two markups' worth of loss.
      expect(roundTrip, closeTo(100.0 * 0.975 * 0.975, 0.0001));
    });

    test('costs money in each direction independently', () {
      for (final (from, to) in [(usd, eur), (eur, usd)]) {
        final market = rate(from, to);
        final card = rate(from, to, source: RateSource.card);
        expect(
          card,
          lessThan(market),
          reason: '${from.code}→${to.code} should be worse than mid-market',
        );
      }
    });

    test('a zero markup matches the market rate', () {
      expect(
        rate(usd, eur, source: RateSource.card, markup: 0),
        rate(usd, eur),
      );
    });
  });

  group('effectiveRates', () {
    test('returns the seeds when nothing has been fetched', () {
      expect(effectiveRates({}), kSeedRates);
    });

    test('live rates win over seeds, and seeds fill the gaps', () {
      final merged = effectiveRates({'EUR': 0.1234});
      expect(merged['EUR'], 0.1234);
      expect(merged['JPY'], kSeedRates['JPY']);
    });
  });
}
