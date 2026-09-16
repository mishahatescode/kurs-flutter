import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/models/currency.dart';
import '../../core/models/rate_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/grouped_section.dart';

/// One feed powers every rate in the app. The options differ in who publishes
/// the numbers, how often, and how many currencies they cover — so each is
/// described in plain language rather than by its API hostname.
class DataSourcesScreen extends StatefulWidget {
  const DataSourcesScreen({super.key});

  @override
  State<DataSourcesScreen> createState() => _DataSourcesScreenState();
}

class _DataSourcesScreenState extends State<DataSourcesScreen> {
  late RateProvider _local = context.read<ConverterState>().provider;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        title: const Text('Data Source'),
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        actions: [
          TextButton(
            onPressed: () {
              if (state.setProvider(_local)) state.refreshRates();
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
            header: 'Where rates come from',
            footer: _footer(state),
            children: [
              for (final p in RateProvider.values)
                CheckRow(
                  title: p.displayName,
                  subtitle: p.summary,
                  selected: _local == p,
                  onTap: () => setState(() => _local = p),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _footer(ConverterState state) {
    if (_local != state.provider) {
      return 'Tap Apply to switch — rates and currency coverage refresh '
          'right after.';
    }
    final count = state.supportedCount;
    if (count == null) {
      return 'Coverage will show here after the first successful refresh.';
    }
    return '$count of ${kCurrencies.length} currencies available from '
        'this source.';
  }
}
