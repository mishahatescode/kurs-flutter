# core

Everything the app *knows* and *does*, with no Flutter widgets in it.

- `models/` — plain data types (a currency, a rate, a conversion result)
- `services/` — fetching rates, caching, persistence
- conversion, rounding and formatting logic

**Rule: no `import 'package:flutter/material.dart'` in this directory.**
Importing `dart:ui` or `foundation` for `ChangeNotifier` is fine; importing
widgets is not. If core needs a widget, the design is wrong — the UI should be
reading a value out of core instead.

Everything here is testable without a device, which is what lets it be
developed and debugged on Windows. Keep it that way.
