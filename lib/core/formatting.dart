import 'package:intl/intl.dart';

import 'models/currency.dart';

/// The separator [localeId] uses between the integer and fractional part.
String decimalSeparatorFor(String localeId) =>
    NumberFormat.decimalPattern(localeId).symbols.DECIMAL_SEP;

/// A finished amount, grouped and padded to the currency's decimal places.
///
/// e.g. 1234.5 USD in `en_US` → "1,234.50"; in `de_DE` → "1.234,50".
String formatAmount(
  double value, {
  required int decimalPlaces,
  required String localeId,
}) {
  if (value.isNaN || value.isInfinite) return '0';
  return NumberFormat.decimalPatternDigits(
    locale: localeId,
    decimalDigits: decimalPlaces,
  ).format(value);
}

/// An amount rendered back into the raw input buffer: no grouping, a plain
/// `.` separator, no trailing zero padding.
///
/// Used when a value moves from one side of the converter to the other (a
/// swap, or typing on the target row) and has to become typeable text again.
/// It is deliberately *not* locale-aware — the buffer is always canonical and
/// only gains locale separators at display time.
String formatAmountRaw(double value, {required int decimalPlaces}) {
  if (value.isNaN || value.isInfinite) return '0';
  final s = value.toStringAsFixed(decimalPlaces);
  if (!s.contains('.')) return s;
  return s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

/// The raw input buffer as it should appear on screen.
///
/// Groups the integer part live as digits are typed ("2039774" reads as
/// "2,039,774") and reattaches anything after the decimal point exactly as
/// typed — grouping digits still being entered would fight the cursor, and a
/// trailing separator has to survive so "1." does not collapse back to "1".
String formatInputForDisplay(String raw, {required String localeId}) {
  final sep = decimalSeparatorFor(localeId);
  final dot = raw.indexOf('.');
  if (dot < 0) return _groupedInteger(raw, localeId);
  return _groupedInteger(raw.substring(0, dot), localeId) +
      sep +
      raw.substring(dot + 1);
}

String _groupedInteger(String digits, String localeId) {
  final value = double.tryParse(digits) ?? 0;
  return NumberFormat.decimalPatternDigits(
    locale: localeId,
    decimalDigits: 0,
  ).format(value);
}

/// "just now" / "1 min ago" / "42 min ago" / "2 hours ago".
String updatedAgoText(DateTime? lastUpdated, {DateTime? now}) {
  if (lastUpdated == null) return 'just now';
  final mins = (now ?? DateTime.now()).difference(lastUpdated).inMinutes;
  if (mins < 1) return 'just now';
  if (mins == 1) return '1 min ago';
  if (mins < 60) return '$mins min ago';
  final hours = (mins / 60).round();
  return hours == 1 ? '1 hour ago' : '$hours hours ago';
}

/// The worked example shown beside each option on the Formatting screen.
String sampleFormat(String localeId) =>
    formatAmount(1234567.89, decimalPlaces: 2, localeId: localeId);

/// Parses the raw input buffer. The buffer is always canonical (`.`), so this
/// is not locale-aware by design.
double parseAmount(String raw) => double.tryParse(raw) ?? 0;

/// Strips grouping separators out of a displayed amount so what lands on the
/// clipboard is a number another app will accept.
String plainCopyValue(String displayed, {required String localeId}) {
  final sep = decimalSeparatorFor(localeId);
  final buffer = StringBuffer();
  for (final ch in displayed.split('')) {
    if (ch == sep) {
      buffer.write('.');
    } else if (RegExp(r'[0-9\-]').hasMatch(ch)) {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

/// Currencies from the full list that the last fetch actually returned.
/// Real, source-dependent coverage rather than the app's fixed total — the
/// ECB covers far fewer currencies than a broad aggregator.
int supportedCurrencyCount(Map<String, double> rates) =>
    kCurrencies.where((c) => rates.containsKey(c.code)).length;
