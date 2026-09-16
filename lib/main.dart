import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/converter_state.dart';
import 'core/services/exchange_rate_service.dart';
import 'core/services/persistence_service.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage is read once up front so the rest of the app can be synchronous —
  // restoring the last pair should not make the first frame wait on disk.
  final storage = await PersistenceService.load();
  final state = ConverterState(storage, HttpExchangeRateService());

  // Deliberately not awaited: the app opens on cached or seed rates and the
  // fetch lands when it lands.
  state.refreshRates();

  runApp(KursApp(state: state));
}

class KursApp extends StatelessWidget {
  const KursApp({super.key, required this.state});

  final ConverterState state;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: state,
      child: Consumer<ConverterState>(
        builder: (context, state, _) => MaterialApp(
          title: 'Kurs',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: switch (state.isDarkMode) {
            null => ThemeMode.system,
            true => ThemeMode.dark,
            false => ThemeMode.light,
          },
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
