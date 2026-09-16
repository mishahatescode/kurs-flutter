import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/models/rate_source.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped_section.dart';
import 'data_sources_screen.dart';

class RateSourceScreen extends StatefulWidget {
  const RateSourceScreen({super.key});

  @override
  State<RateSourceScreen> createState() => _RateSourceScreenState();
}

class _RateSourceScreenState extends State<RateSourceScreen> {
  late RateSource _source = context.read<ConverterState>().rateSource;
  late double _markup = context.read<ConverterState>().bankMarkup;

  static const _presets = [0.0, 1.5, 2.5, 3.5, 5.0];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        title: const Text('Rate Source'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: () {
              state
                ..setRateSource(_source)
                ..setBankMarkup(_markup);
              Navigator.of(context).pop();
            },
            child: const Text(
              'Apply',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          GroupedSection(
            header: 'Rate Source',
            children: [
              for (final s in RateSource.values)
                CheckRow(
                  title: s.displayName,
                  subtitle: s.description,
                  leading: Icon(
                    s == RateSource.market
                        ? Icons.trending_up
                        : Icons.credit_card,
                    size: 20,
                    color: AppTheme.accent,
                  ),
                  selected: _source == s,
                  onTap: () => setState(() => _source = s),
                ),
            ],
          ),
          if (_source == RateSource.card)
            GroupedSection(
              header: 'Bank/Card Markup',
              footer:
                  'Taken off the rate from your data source. 2.5% is '
                  'typical for many banks.',
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Markup', style: TextStyle(fontSize: 17)),
                          const Spacer(),
                          Text(
                            '${_markup.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _markup,
                        max: 12,
                        divisions: 24,
                        label: '${_markup.toStringAsFixed(1)}%',
                        onChanged: (v) => setState(() => _markup = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final preset in _presets)
                              _PresetChip(
                                value: preset,
                                selected: _markup == preset,
                                onTap: () => setState(() => _markup = preset),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          GroupedSection(
            footer: 'Where every rate in the app comes from.',
            children: [
              DisclosureRow(
                title: 'Data Source',
                value: state.provider.displayName,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const DataSourcesScreen(),
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
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final double value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = value == 0 ? '0%' : '${value.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : colors.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
