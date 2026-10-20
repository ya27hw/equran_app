import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

class AppSliderTheme {
  const AppSliderTheme._();

  static SliderThemeData standard(BuildContext context) {
    final SliderThemeData base = SliderTheme.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return base.copyWith(
      trackHeight: 8,
      inactiveTrackColor: scheme.surfaceContainerHighest,
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.14),
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
    );
  }

  /// The thin, quiet track of the reading player.
  static SliderThemeData player(BuildContext context) {
    final SliderThemeData base = SliderTheme.of(context);
    final EquranColors colors = context.equranColors;
    final EquranTokens tokens = context.equranTokens;
    return base.copyWith(
      trackHeight: 4,
      inactiveTrackColor: tokens.hair2,
      activeTrackColor: colors.primary,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withValues(alpha: 0.14),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 6.5,
        elevation: 0,
        pressedElevation: 0,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 15),
      trackShape: const RoundedRectSliderTrackShape(),
    );
  }
}
