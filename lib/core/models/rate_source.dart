/// How the displayed rate is derived from whichever data source is selected.
///
/// There is deliberately no separate "ECB" case: being an ECB rate is a
/// property of the *feed* you pull from (Frankfurter publishes the ECB's
/// numbers), not of a calculation applied afterwards. Picking the feed lives
/// in [RateProvider]; this only covers what is done to those numbers.
enum RateSource {
  market(
    'Market',
    'Market rate',
    'The plain rate from your data source — nothing added',
  ),
  card(
    'Card/Bank',
    'Card or bank',
    'Like paying with a card abroad — a small fee added on top',
  );

  const RateSource(this.storageKey, this.displayName, this.description);

  /// Stable string written to storage. Never change these — renaming one
  /// silently resets the setting for everyone who had it selected.
  final String storageKey;
  final String displayName;
  final String description;

  static RateSource? fromStorageKey(String? key) {
    for (final s in RateSource.values) {
      if (s.storageKey == key) return s;
    }
    return null;
  }
}
