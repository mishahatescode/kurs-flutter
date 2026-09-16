import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/formatting.dart';
import '../../core/models/number_locale_option.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped_section.dart';
import 'rate_source_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ConverterState _state = context.read<ConverterState>();

  /// Appearance previews live as you tap, so Cancel needs the value the
  /// screen was opened with in order to put it back.
  late final bool? _originalDarkMode = _state.isDarkMode;

  late bool _offline = _state.isOffline;
  late String _localeId = _state.numberLocaleId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: TextButton(
          onPressed: () {
            _state.setDarkMode(_originalDarkMode);
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: () {
              // Appearance is already applied by the picker; this commits it
              // alongside everything else.
              _state
                ..setNumberLocale(_localeId)
                ..setOffline(_offline);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          GroupedSection(
            header: 'Appearance',
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _appearanceTag(state.isDarkMode),
                    children: const {
                      0: Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('System'),
                      ),
                      1: Text('Light'),
                      2: Text('Dark'),
                    },
                    // Applied on selection rather than on Save — waiting made
                    // the control feel broken, and the theme is the one
                    // setting you judge by looking at it.
                    onValueChanged: (v) =>
                        _state.setDarkMode(_darkModeFor(v ?? 0)),
                  ),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Network',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Color(0xFFFF9500)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offline Mode',
                            style: TextStyle(fontSize: 17),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Use cached or seed rates only',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _offline,
                      onChanged: (v) => setState(() => _offline = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Rate Source',
            footer:
                'Use the plain market rate, or add a card/bank fee '
                'on top.',
            children: [
              DisclosureRow(
                title: 'Rate Source',
                value: state.rateSource.displayName,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const RateSourceScreen(),
                  ),
                ),
              ),
            ],
          ),
          GroupedSection(
            header: 'Formatting',
            footer:
                'Controls how amounts are grouped and separated — '
                "independent of your device's language.",
            children: [
              for (final option in kNumberLocales)
                CheckRow(
                  title: option.name,
                  subtitle: sampleFormat(option.id),
                  selected: _localeId == option.id,
                  onTap: () => setState(() => _localeId = option.id),
                ),
            ],
          ),
          GroupedSection(
            header: 'About',
            children: const [
              _InfoRow(label: 'Version', value: '1.0.0'),
              _InfoRow(label: 'Bundle', value: 'com.onedollarapps.kurs'),
            ],
          ),
          GroupedSection(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _state
                    ..clearRecentPairs()
                    ..clearRecentCurrencies();
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(context).pop();
                  messenger
                    ..clearSnackBars()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Cleared recent pairs'),
                        behavior: SnackBarBehavior.floating,
                        shape: StadiumBorder(),
                        margin: EdgeInsets.fromLTRB(20, 0, 20, 24),
                      ),
                    );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Color(0xFFFF3B30),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Clear Recent Pairs',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static int _appearanceTag(bool? isDark) => switch (isDark) {
    null => 0,
    false => 1,
    true => 2,
  };

  static bool? _darkModeFor(int tag) => switch (tag) {
    1 => false,
    2 => true,
    _ => null,
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 17, color: colors.secondaryLabel),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
