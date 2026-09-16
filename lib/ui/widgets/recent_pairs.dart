import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/models/currency.dart';
import '../../core/models/currency_pair.dart';
import '../theme/app_theme.dart';

class RecentPairs extends StatelessWidget {
  const RecentPairs({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    if (state.recentPairs.isEmpty) return const _EmptyState();

    final colors = context.colors;
    final pairs = state.recentPairs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            'Recent Pairs',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (var i = 0; i < pairs.length; i++) ...[
                _PairRow(pair: pairs[i]),
                if (i < pairs.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Divider(height: 0.5, color: colors.separator),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 28, color: colors.secondaryLabel),
          const SizedBox(height: 8),
          Text(
            'No recent conversions',
            style: TextStyle(fontSize: 15, color: colors.secondaryLabel),
          ),
          const SizedBox(height: 2),
          Text(
            'Pairs you convert will show up here',
            style: TextStyle(fontSize: 12, color: colors.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({required this.pair});

  final CurrencyPair pair;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;
    final from = kCurrencyByCode[pair.from];
    final to = kCurrencyByCode[pair.to];
    if (from == null || to == null) return const SizedBox.shrink();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => state.applyPair(pair),
      onLongPress: () => state.removeRecentPair(pair),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              child: Text(
                '${from.flag}${to.flag}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${from.code} → ${to.code}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${from.name} → ${to.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.format(state.rateFor(from, to), to),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'per 1 ${from.code}',
                  style: TextStyle(fontSize: 11, color: colors.secondaryLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
