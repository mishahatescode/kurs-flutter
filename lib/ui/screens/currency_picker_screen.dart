import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/models/currency.dart';
import '../theme/app_theme.dart';

/// Pops with the chosen [Currency], or null if cancelled.
class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({super.key, required this.forSource});

  final bool forSource;

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;
    final searching = _query.trim().isNotEmpty;

    final pinned = state.pinned
        .map((c) => kCurrencyByCode[c])
        .whereType<Currency>()
        .toList();

    // A pinned currency is already at the top; repeating it just below is
    // noise.
    final recent = state.recentCurrencies
        .where((c) => !state.isPinned(c))
        .map((c) => kCurrencyByCode[c])
        .whereType<Currency>()
        .toList();

    final q = _query.toLowerCase().trim();
    final all = searching
        ? kCurrencies
              .where(
                (c) =>
                    c.code.toLowerCase().contains(q) ||
                    c.name.toLowerCase().contains(q),
              )
              .toList()
        : kCurrencies;

    return Scaffold(
      backgroundColor: colors.groupedBackground,
      appBar: AppBar(
        title: Text(widget.forSource ? 'From' : 'To'),
        // Cancel sits on the leading edge per the HIG — the trailing slot
        // belongs to the confirming action.
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        leadingWidth: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search currency…',
              leading: Icon(Icons.search, color: colors.secondaryLabel),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(colors.fill),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          if (!searching && pinned.isNotEmpty)
            _Section(title: 'Pinned', currencies: pinned, onSelect: _select),
          if (!searching && recent.isNotEmpty)
            _Section(title: 'Recent', currencies: recent, onSelect: _select),
          _Section(
            title: searching ? 'Results' : 'All Currencies',
            currencies: all,
            onSelect: _select,
          ),
          if (all.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No currency matches “$_query”',
                  style: TextStyle(color: colors.secondaryLabel),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _select(Currency currency) => Navigator.of(context).pop(currency);
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.currencies,
    required this.onSelect,
  });

  final String title;
  final List<Currency> currencies;
  final ValueChanged<Currency> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (currencies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              color: colors.secondaryLabel,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < currencies.length; i++) ...[
                _CurrencyRow(
                  currency: currencies[i],
                  onSelect: () => onSelect(currencies[i]),
                ),
                if (i < currencies.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 64),
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

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({required this.currency, required this.onSelect});

  final Currency currency;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;
    final pinned = state.isPinned(currency.code);

    // A plain row rather than a button, so the star can be its own tappable
    // control — a button inside a button swallows the inner tap.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(currency.flag, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    currency.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => state.togglePin(currency.code),
              icon: Icon(
                pinned ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 22,
                color: pinned ? const Color(0xFFFFCC00) : colors.tertiaryLabel,
              ),
              tooltip: pinned
                  ? 'Unpin ${currency.code}'
                  : 'Pin ${currency.code}',
            ),
          ],
        ),
      ),
    );
  }
}
