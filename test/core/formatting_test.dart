import 'package:flutter_test/flutter_test.dart';
import 'package:kurs/core/formatting.dart';

void main() {
  group('formatAmount', () {
    test('groups and pads to the currency decimals', () {
      expect(
        formatAmount(1234.5, decimalPlaces: 2, localeId: 'en_US'),
        '1,234.50',
      );
      expect(
        formatAmount(1234.5, decimalPlaces: 0, localeId: 'en_US'),
        '1,235',
      );
    });

    test('follows the chosen locale, not the device', () {
      expect(
        formatAmount(1234.5, decimalPlaces: 2, localeId: 'de_DE'),
        '1.234,50',
      );
      // India groups in lakh/crore, not thousands.
      expect(
        formatAmount(1234567.89, decimalPlaces: 2, localeId: 'en_IN'),
        '12,34,567.89',
      );
    });

    test('three-decimal currencies keep all three', () {
      expect(
        formatAmount(1.2345, decimalPlaces: 3, localeId: 'en_US'),
        '1.234',
      );
    });

    test('never renders NaN or infinity to the user', () {
      expect(
        formatAmount(double.nan, decimalPlaces: 2, localeId: 'en_US'),
        '0',
      );
      expect(
        formatAmount(double.infinity, decimalPlaces: 2, localeId: 'en_US'),
        '0',
      );
    });
  });

  group('formatAmountRaw', () {
    test('drops grouping and trailing zeros so the result is typeable', () {
      expect(formatAmountRaw(1234.5, decimalPlaces: 2), '1234.5');
      expect(formatAmountRaw(5.0, decimalPlaces: 2), '5');
      expect(formatAmountRaw(100.0, decimalPlaces: 0), '100');
    });

    test('rounds to the currency decimals', () {
      expect(formatAmountRaw(5.4567, decimalPlaces: 2), '5.46');
      expect(formatAmountRaw(1234.6, decimalPlaces: 0), '1235');
    });
  });

  group('formatInputForDisplay', () {
    test('groups the integer part live as digits arrive', () {
      expect(formatInputForDisplay('2039774', localeId: 'en_US'), '2,039,774');
    });

    test('leaves the fraction exactly as typed', () {
      // Grouping digits mid-entry would fight the cursor, and a bare trailing
      // separator has to survive or "1." collapses back to "1".
      expect(formatInputForDisplay('1.', localeId: 'en_US'), '1.');
      expect(formatInputForDisplay('1.05', localeId: 'en_US'), '1.05');
      expect(formatInputForDisplay('1234.50', localeId: 'en_US'), '1,234.50');
    });

    // Regression: the SwiftUI build stored the locale's separator in the input
    // buffer, then split the buffer on "." to render it. Under de-DE the
    // buffer held "1,5", the split found no ".", and the whole string parsed
    // as 0 — so typing a decimal showed "0". The buffer is now always
    // canonical and only gains a locale separator at display time.
    test('renders a decimal under a comma-separator locale', () {
      expect(formatInputForDisplay('1.5', localeId: 'de_DE'), '1,5');
      expect(formatInputForDisplay('1234.5', localeId: 'de_DE'), '1.234,5');
    });
  });

  group('updatedAgoText', () {
    final t0 = DateTime(2026, 9, 16, 12, 0);

    test('reads as "just now" before a minute has passed', () {
      expect(updatedAgoText(null), 'just now');
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(seconds: 59))),
        'just now',
      );
    });

    test('singular and plural minutes', () {
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(minutes: 1))),
        '1 min ago',
      );
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(minutes: 42))),
        '42 min ago',
      );
    });

    test('switches to hours at the hour boundary', () {
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(minutes: 59))),
        '59 min ago',
      );
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(minutes: 60))),
        '1 hour ago',
      );
      expect(
        updatedAgoText(t0, now: t0.add(const Duration(hours: 3))),
        '3 hours ago',
      );
    });
  });

  group('plainCopyValue', () {
    test('strips grouping so another app will accept the number', () {
      expect(plainCopyValue('1,234.50', localeId: 'en_US'), '1234.50');
      expect(plainCopyValue('1.234,50', localeId: 'de_DE'), '1234.50');
    });
  });
}
