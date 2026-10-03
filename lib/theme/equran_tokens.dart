import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';

/// Opt-in redesign colours. Existing [EquranColors] consumers stay unchanged.
@immutable
class EquranTokens extends ThemeExtension<EquranTokens> {
  const EquranTokens({
    required this.text2,
    required this.muted,
    required this.hair,
    required this.hair2,
    required this.filled,
    required this.emText,
    required this.emWash,
    required this.gold,
    required this.goldText,
    required this.goldWash,
    required this.danger,
    required this.featA,
    required this.featB,
    required this.featText2,
    required this.glow,
    required this.dock,
    required this.scrim,
    required this.shadow,
  });

  final Color text2;
  final Color muted;
  final Color hair;
  final Color hair2;
  final Color filled;
  final Color emText;
  final Color emWash;
  final Color gold;
  final Color goldText;
  final Color goldWash;
  final Color danger;
  final Color featA;
  final Color featB;
  final Color featText2;
  final Color glow;
  final Color dock;
  final Color scrim;
  final Color shadow;

  /// Fixed derivation rules from docs/redesign/derive_tokens.py.
  /// Mode follows the source background; a black background suppresses glow.
  factory EquranTokens.fromColors(EquranColors colors) {
    final bool dark = colors.background.computeLuminance() < 0.5;
    final Color ink = colors.textPrimary;
    final Color toward = dark ? Colors.white : Colors.black;
    final List<Color> backgrounds = [
      colors.surface,
      colors.surfaceAlt,
      colors.background,
    ];
    final Color text2 = ensure(
      colors.textSecondary,
      against: backgrounds,
      target: 4.5,
      toward: ink,
    );
    final Color muted = ensure(
      colors.textMuted,
      against: backgrounds,
      target: 4.5,
      toward: text2,
    );
    Color filled = colors.primary;
    if (contrast(filled, Colors.white) < 4.5) {
      filled = colors.primaryStrong;
    }
    if (contrast(filled, Colors.white) < 4.5) {
      filled = ensure(
        filled,
        against: [Colors.white],
        target: 4.5,
        toward: Colors.black,
      );
    }
    final Color emText = ensure(
      dark ? colors.primarySoft : colors.primary,
      against: [colors.surface, colors.surfaceAlt],
      target: 4.5,
      toward: toward,
    );
    final double goldAlpha = dark ? 0.12 : 0.14;
    final Color washSurface = mix(colors.surface, colors.accentGold, goldAlpha);
    final Color featA = colors.primaryGradientStart;
    final Color featB = mix(featA, Colors.black, 0.45);
    return EquranTokens(
      text2: text2,
      muted: muted,
      hair: ink.withValues(alpha: dark ? 0.10 : 0.09),
      hair2: ink.withValues(alpha: dark ? 0.20 : 0.17),
      filled: filled,
      emText: emText,
      emWash: (dark ? emText : colors.primary).withValues(
        alpha: dark ? 0.10 : 0.09,
      ),
      gold: dark
          ? colors.accentGold
          : ensure(
              colors.accentGold,
              against: [colors.surface],
              target: 3.0,
              toward: Colors.black,
            ),
      goldText: ensure(
        dark ? mix(colors.accentGold, Colors.white, 0.15) : colors.accentGold,
        against: [colors.surface, washSurface, colors.background],
        target: 4.5,
        toward: toward,
      ),
      goldWash: colors.accentGold.withValues(alpha: goldAlpha),
      danger: ensure(
        dark ? const Color(0xFFE69A8B) : const Color(0xFFB04B38),
        against: [colors.surface, colors.surfaceAlt],
        target: 4.5,
        toward: toward,
      ),
      featA: featA,
      featB: featB,
      featText2: ensure(
        const Color(0xFFC5D5CD),
        against: [featA, featB],
        target: 4.5,
        toward: Colors.white,
      ),
      glow: colors.background == Colors.black
          ? Colors.transparent
          : colors.primary.withValues(alpha: dark ? 0.20 : 0.09),
      dock: colors.surface.withValues(alpha: dark ? 0.84 : 0.88),
      scrim: (dark ? Colors.black : colors.shadow).withValues(
        alpha: dark ? 0.62 : 0.42,
      ),
      // The CSS shadow's colour; offset and blur belong to later widgets.
      shadow: (dark ? Colors.black : colors.shadow).withValues(
        alpha: dark ? 0.40 : 0.10,
      ),
    );
  }

  /// Per-channel sRGB blend, rounded before contrast evaluation like Python.
  static Color mix(Color a, Color b, double t) {
    int channel(double start, double end) =>
        ((start + (end - start) * t) * 255).round().clamp(0, 255);
    return Color.fromARGB(
      channel(a.a, b.a),
      channel(a.r, b.r),
      channel(a.g, b.g),
      channel(a.b, b.b),
    );
  }

  /// WCAG contrast for opaque foreground/background colours.
  static double contrast(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// Returns the first of 40 equal steps that passes on every background.
  /// If none passes, returns [toward], matching the reference implementation.
  static Color ensure(
    Color color, {
    required List<Color> against,
    required double target,
    required Color toward,
  }) {
    Color candidate = color;
    for (int i = 0; i <= 40; i++) {
      candidate = mix(color, toward, i / 40);
      if (against.every(
        (background) => contrast(candidate, background) >= target,
      )) {
        return candidate;
      }
    }
    return candidate;
  }

  @override
  EquranTokens copyWith({
    Color? text2,
    Color? muted,
    Color? hair,
    Color? hair2,
    Color? filled,
    Color? emText,
    Color? emWash,
    Color? gold,
    Color? goldText,
    Color? goldWash,
    Color? danger,
    Color? featA,
    Color? featB,
    Color? featText2,
    Color? glow,
    Color? dock,
    Color? scrim,
    Color? shadow,
  }) => EquranTokens(
    text2: text2 ?? this.text2,
    muted: muted ?? this.muted,
    hair: hair ?? this.hair,
    hair2: hair2 ?? this.hair2,
    filled: filled ?? this.filled,
    emText: emText ?? this.emText,
    emWash: emWash ?? this.emWash,
    gold: gold ?? this.gold,
    goldText: goldText ?? this.goldText,
    goldWash: goldWash ?? this.goldWash,
    danger: danger ?? this.danger,
    featA: featA ?? this.featA,
    featB: featB ?? this.featB,
    featText2: featText2 ?? this.featText2,
    glow: glow ?? this.glow,
    dock: dock ?? this.dock,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  EquranTokens lerp(covariant EquranTokens? other, double t) {
    if (other == null) return this;
    return EquranTokens(
      text2: Color.lerp(text2, other.text2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      hair: Color.lerp(hair, other.hair, t)!,
      hair2: Color.lerp(hair2, other.hair2, t)!,
      filled: Color.lerp(filled, other.filled, t)!,
      emText: Color.lerp(emText, other.emText, t)!,
      emWash: Color.lerp(emWash, other.emWash, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldText: Color.lerp(goldText, other.goldText, t)!,
      goldWash: Color.lerp(goldWash, other.goldWash, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      featA: Color.lerp(featA, other.featA, t)!,
      featB: Color.lerp(featB, other.featB, t)!,
      featText2: Color.lerp(featText2, other.featText2, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      dock: Color.lerp(dock, other.dock, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension EquranTokensContext on BuildContext {
  EquranTokens get equranTokens =>
      Theme.of(this).extension<EquranTokens>() ??
      EquranTokens.fromColors(equranColors);
}
