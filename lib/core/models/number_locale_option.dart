/// The number-formatting locale (grouping and decimal separators) is chosen
/// independently of the device locale — someone can run an English phone and
/// still want German-style separators.
class NumberLocaleOption {
  const NumberLocaleOption(this.id, this.name);

  /// An ICU locale id, underscore-separated as `intl` expects.
  final String id;
  final String name;
}

const List<NumberLocaleOption> kNumberLocales = [
  NumberLocaleOption('en_US', 'United States'),
  NumberLocaleOption('de_DE', 'Germany'),
  NumberLocaleOption('fr_FR', 'France'),
  NumberLocaleOption('en_IN', 'India'),
];
