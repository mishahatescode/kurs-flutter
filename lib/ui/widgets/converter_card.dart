import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/formatting.dart';
import '../../core/models/currency.dart';
import '../screens/currency_picker_screen.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The two-row converter, with the swap button floating over the divider.
class ConverterCard extends StatelessWidget {
  const ConverterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.centerRight,
          children: [
            Column(
              children: [
                _Row(
                  currency: state.source,
                  value: state.sourceDisplay,
                  isActive: state.isSourceActive,
                  onPickCurrency: () => _pick(context, forSource: true),
                  onTapRow: () => state.setActiveRow(source: true),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Divider(height: 0.5, color: colors.separator),
                ),
                _Row(
                  currency: state.target,
                  value: state.targetDisplay,
                  isActive: !state.isSourceActive,
                  onPickCurrency: () => _pick(context, forSource: false),
                  onTapRow: () => state.setActiveRow(source: false),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Pressable(
                onTap: state.swapCurrencies,
                child: Semantics(
                  button: true,
                  label: 'Swap currencies',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_vert,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, {required bool forSource}) async {
    final state = context.read<ConverterState>();
    final picked = await Navigator.of(context).push<Currency>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CurrencyPickerScreen(forSource: forSource),
      ),
    );
    if (picked != null) state.selectCurrency(picked, forSource: forSource);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.currency,
    required this.value,
    required this.isActive,
    required this.onPickCurrency,
    required this.onTapRow,
  });

  final Currency currency;
  final String value;
  final bool isActive;
  final VoidCallback onPickCurrency;
  final VoidCallback onTapRow;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = context.read<ConverterState>();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapRow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Loose, so the chip takes only what it needs but yields rather
            // than overflowing when the currency name is long.
            Flexible(
              flex: 5,
              child: Pressable(
                onTap: onPickCurrency,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.fill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.flag, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currency.code,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currency.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 18,
                        color: colors.secondaryLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Reserves room for the floating swap button on the card's edge.
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 58),
                child: GestureDetector(
                  onTap: onTapRow,
                  onLongPress: () => _copy(context, state),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Theme.of(context).colorScheme.onSurface
                            : colors.secondaryLabel,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, ConverterState state) {
    final plain = plainCopyValue(value, localeId: state.numberLocaleId);
    Clipboard.setData(ClipboardData(text: plain));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Copied ${currency.code} $value'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          shape: const StadiumBorder(),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        ),
      );
  }
}
