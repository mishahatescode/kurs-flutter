/// Where every rate in the app comes from. One choice powers everything —
/// what differs is who publishes the numbers, how often, and how many
/// currencies they cover.
enum RateProvider {
  frankfurter(
    'frankfurter',
    'European Central Bank',
    "Europe's official rate. Published once each weekday afternoon, so it "
        'stays put during the day.',
  ),
  openERAPI(
    'openERAPI',
    'Bank average',
    'Averaged across many banks and exchanges. Updated daily, and covers '
        'more currencies than the ECB.',
  ),
  fawazCurrencyAPI(
    'fawazCurrencyAPI',
    'Widest coverage',
    'A free community feed with the longest currency list. Updated daily.',
  );

  const RateProvider(this.storageKey, this.displayName, this.summary);

  /// Stable string written to storage — matches the Swift app's raw values.
  final String storageKey;
  final String displayName;

  /// Plain-language explanation of how this feed differs from the others.
  /// Deliberately not the API hostname; users do not pick a feed by URL.
  final String summary;

  static RateProvider? fromStorageKey(String? key) {
    for (final p in RateProvider.values) {
      if (p.storageKey == key) return p;
    }
    return null;
  }
}
