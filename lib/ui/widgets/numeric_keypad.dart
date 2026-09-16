import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/converter_state.dart';
import '../../core/formatting.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

/// The always-visible keypad. Deliberately not the system keyboard: the app
/// only ever accepts digits, and a custom pad keeps the converter and the
/// keys on screen together.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key});

  static const _rows = [
    ['7', '8', '9'],
    ['4', '5', '6'],
    ['1', '2', '3'],
    ['decimal', '0', 'back'],
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConverterState>();
    final colors = context.colors;
    final decimalsAllowed = state.activeCurrency.decimalPlaces > 0;

    // Short phones cannot afford the full-height keys and still show the
    // converter card above them.
    final keyHeight = MediaQuery.sizeOf(context).height < 700 ? 52.0 : 60.0;

    return Container(
      color: colors.groupedBackground,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 0.5, color: colors.separator),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  for (final row in _rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          for (final key in row)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: _Key(
                                  keyId: key,
                                  height: keyHeight,
                                  disabled:
                                      key == 'decimal' && !decimalsAllowed,
                                  localeId: state.numberLocaleId,
                                  onTap: () => state.keypadTap(key),
                                  onLongPress: key == 'back'
                                      ? state.clearAmount
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.keyId,
    required this.height,
    required this.disabled,
    required this.localeId,
    required this.onTap,
    this.onLongPress,
  });

  final String keyId;
  final double height;
  final bool disabled;
  final String localeId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isBackspace = keyId == 'back';
    final fg = Theme.of(context).colorScheme.onSurface;

    final label = switch (keyId) {
      'decimal' => decimalSeparatorFor(localeId),
      'back' => null,
      _ => keyId,
    };

    return Semantics(
      button: true,
      enabled: !disabled,
      label: switch (keyId) {
        'decimal' => 'Decimal point',
        'back' => 'Delete',
        _ => keyId,
      },
      child: Pressable(
        onTap: disabled ? null : onTap,
        onLongPress: disabled ? null : onLongPress,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isBackspace
                ? colors.backspaceBackground
                : colors.keyBackground,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 0.5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: label == null
              ? Icon(
                  Icons.backspace_outlined,
                  size: 20,
                  color: disabled ? colors.tertiaryLabel : fg,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    color: disabled ? colors.tertiaryLabel : fg,
                  ),
                ),
        ),
      ),
    );
  }
}
