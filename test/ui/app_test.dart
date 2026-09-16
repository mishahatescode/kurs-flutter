import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurs/core/converter_state.dart';
import 'package:kurs/core/models/rate_provider.dart';
import 'package:kurs/core/services/exchange_rate_service.dart';
import 'package:kurs/core/services/storage.dart';
import 'package:kurs/main.dart';

class _StubExchange implements ExchangeRateService {
  @override
  Future<Map<String, double>> fetchRates(RateProvider provider) async => const {
    'USD': 1.0,
    'EUR': 0.5,
  };
}

void main() {
  /// A phone-sized surface — the keypad and the converter card together do not
  /// fit the 800×600 default, and overflow would fail the test for the wrong
  /// reason.
  Future<void> pumpApp(WidgetTester tester, ConverterState state) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KursApp(state: state));
    await tester.pumpAndSettle();
  }

  ConverterState buildState() {
    final storage = InMemoryStorage()
      ..cachedRates = (rates: {'USD': 1.0, 'EUR': 0.5}, date: DateTime(2026));
    return ConverterState(storage, _StubExchange());
  }

  testWidgets('opens on the converter with both currencies visible', (
    tester,
  ) async {
    await pumpApp(tester, buildState());

    expect(find.text('Kurs'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
  });

  testWidgets('typing on the keypad updates the converted amount', (
    tester,
  ) async {
    final state = buildState();
    await pumpApp(tester, state);

    await tester.tap(find.widgetWithText(Semantics, '2').first);
    await tester.pump();

    // The buffer starts at "1", so tapping 2 gives 12 — at 0.5 that is 6.
    expect(state.sourceValue, 12.0);
    expect(state.targetValue, 6.0);
    expect(find.text('6.00'), findsOneWidget);
  });

  testWidgets('the swap button exchanges the two rows', (tester) async {
    final state = buildState();
    await pumpApp(tester, state);

    await tester.tap(find.bySemanticsLabel('Swap currencies'));
    await tester.pumpAndSettle();

    expect(state.source.code, 'EUR');
    expect(state.target.code, 'USD');
  });

  testWidgets('the settings screen opens and cancels back', (tester) async {
    await pumpApp(tester, buildState());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });
}
