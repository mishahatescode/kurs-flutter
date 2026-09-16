import 'models/currency.dart';
import 'models/rate_source.dart';

/// Live rates laid over the built-in seeds.
///
/// A feed with narrow coverage (the ECB publishes ~30 currencies) still leaves
/// every currency in the picker renderable, rather than showing blanks.
Map<String, double> effectiveRates(Map<String, double> live) {
  if (live.isEmpty) return kSeedRates;
  return {...kSeedRates, ...live};
}

/// The rate to multiply a [from] amount by to get [to], with the selected
/// [source] applied.
double conversionRate({
  required Currency from,
  required Currency to,
  required Map<String, double> rates,
  required RateSource source,
  required double bankMarkup,
}) {
  if (from.code == to.code) return 1.0;

  final effective = effectiveRates(rates);
  final fromRate = effective[from.code] ?? kSeedRates[from.code] ?? 1.0;
  final toRate = effective[to.code] ?? kSeedRates[to.code] ?? 1.0;
  if (fromRate <= 0) return 1.0;

  final base = toRate / fromRate;

  switch (source) {
    case RateSource.market:
      return base;
    case RateSource.card:
      // The markup must cost the customer money in *either* direction.
      // Applying `base * (1 + markup)` to each leg independently made a round
      // trip profitable — base is an exact reciprocal, so the two markups
      // compounded into a net gain. A flat `(1 - markup)` penalty on the
      // mid-rate means every conversion lands behind the mid rate and a round
      // trip loses roughly 2× markup, which is what a card actually does.
      return base * (1 - bankMarkup / 100);
  }
}
