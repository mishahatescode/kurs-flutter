import 'package:flutter/material.dart';

/// Colours, typography and shape for the whole app.
///
/// Widgets read from `Theme.of(context)` — they never hardcode a colour.
abstract final class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
  );

  static final ThemeData dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.dark,
    ),
  );
}
