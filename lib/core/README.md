# core

Everything the app *knows* and *does*, with no Flutter widgets in it.

- `models/` — plain data types (a currency, a pair, the rate-source enums)
- `services/` — fetching rates (`ExchangeRateService`) and storage
  (`ConverterStorage`), both **interfaces** with a real and a fake
  implementation, so nothing here needs a device or a plugin to run
- `conversion.dart`, `formatting.dart` — pure functions
- `converter_state.dart` — the `ChangeNotifier` holding all app state

**Rule: no `import 'package:flutter/material.dart'` in this directory.**
`foundation` for `ChangeNotifier` is fine; widgets are not. Icons and colours
are UI concerns — the enums here expose names and descriptions, and
`lib/ui/` maps those to `IconData`.

Everything here is testable without a device, which is what lets it be
developed and debugged on Windows. Keep it that way.
