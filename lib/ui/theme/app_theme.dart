import 'package:flutter/material.dart';

/// The iOS semantic colours the SwiftUI build used, carried over by hand —
/// Flutter has no equivalent of `UIColor.systemGroupedBackground`, and the
/// Material defaults are visibly not these.
@immutable
class KursColors extends ThemeExtension<KursColors> {
  const KursColors({
    required this.groupedBackground,
    required this.cardBackground,
    required this.fill,
    required this.keyBackground,
    required this.backspaceBackground,
    required this.separator,
    required this.tertiaryLabel,
    required this.secondaryLabel,
  });

  /// `systemGroupedBackground` — the page behind the cards.
  final Color groupedBackground;

  /// `secondarySystemGroupedBackground` — the cards themselves.
  final Color cardBackground;

  /// `systemGray6` — the currency selector chip.
  final Color fill;

  /// `secondarySystemGroupedBackground` — a number key.
  final Color keyBackground;

  /// `systemGray3` — the backspace key, deliberately darker than the digits.
  final Color backspaceBackground;

  final Color separator;
  final Color tertiaryLabel;
  final Color secondaryLabel;

  static const light = KursColors(
    groupedBackground: Color(0xFFF2F2F7),
    cardBackground: Colors.white,
    fill: Color(0xFFF2F2F7),
    keyBackground: Colors.white,
    backspaceBackground: Color(0xFFC7C7CC),
    separator: Color(0x4D3C3C43),
    tertiaryLabel: Color(0x4D3C3C43),
    secondaryLabel: Color(0x993C3C43),
  );

  static const dark = KursColors(
    groupedBackground: Colors.black,
    cardBackground: Color(0xFF1C1C1E),
    fill: Color(0xFF2C2C2E),
    keyBackground: Color(0xFF1C1C1E),
    backspaceBackground: Color(0xFF48484A),
    separator: Color(0x99545458),
    tertiaryLabel: Color(0x4DEBEBF5),
    secondaryLabel: Color(0x99EBEBF5),
  );

  @override
  KursColors copyWith({
    Color? groupedBackground,
    Color? cardBackground,
    Color? fill,
    Color? keyBackground,
    Color? backspaceBackground,
    Color? separator,
    Color? tertiaryLabel,
    Color? secondaryLabel,
  }) => KursColors(
    groupedBackground: groupedBackground ?? this.groupedBackground,
    cardBackground: cardBackground ?? this.cardBackground,
    fill: fill ?? this.fill,
    keyBackground: keyBackground ?? this.keyBackground,
    backspaceBackground: backspaceBackground ?? this.backspaceBackground,
    separator: separator ?? this.separator,
    tertiaryLabel: tertiaryLabel ?? this.tertiaryLabel,
    secondaryLabel: secondaryLabel ?? this.secondaryLabel,
  );

  @override
  KursColors lerp(KursColors? other, double t) {
    if (other == null) return this;
    return KursColors(
      groupedBackground: Color.lerp(
        groupedBackground,
        other.groupedBackground,
        t,
      )!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      keyBackground: Color.lerp(keyBackground, other.keyBackground, t)!,
      backspaceBackground: Color.lerp(
        backspaceBackground,
        other.backspaceBackground,
        t,
      )!,
      separator: Color.lerp(separator, other.separator, t)!,
      tertiaryLabel: Color.lerp(tertiaryLabel, other.tertiaryLabel, t)!,
      secondaryLabel: Color.lerp(secondaryLabel, other.secondaryLabel, t)!,
    );
  }
}

extension KursColorsOf on BuildContext {
  KursColors get colors => Theme.of(this).extension<KursColors>()!;
}

abstract final class AppTheme {
  /// iOS `systemBlue`.
  static const accent = Color(0xFF007AFF);

  static ThemeData _base(Brightness brightness, KursColors colors) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
        primary: accent,
      ),
      scaffoldBackgroundColor: colors.groupedBackground,
      extensions: [colors],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: colors.separator,
        space: 1,
        thickness: 0.5,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.groupedBackground,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  static final ThemeData light = _base(Brightness.light, KursColors.light);
  static final ThemeData dark = _base(Brightness.dark, KursColors.dark);
}
