import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:equran/theme/equran_colors.dart';
import 'package:equran/theme/equran_spacing.dart';
import 'package:equran/theme/equran_tokens.dart';
import 'package:flutter/material.dart';

class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.equranTokens;
    final radius = BorderRadius.circular(EquranRadii.xxl);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: _HeroGradient([tokens.featA, tokens.featB]),
        border: Border.all(color: tokens.gold.withValues(alpha: 0.22)),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: EquranColors.dark.textPrimary),
          child: IconTheme.merge(
            data: IconThemeData(color: EquranColors.dark.textPrimary),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// CSS gradient angles use physical pixels, including on non-square panels.
class _HeroGradient extends LinearGradient {
  const _HeroGradient(List<Color> colors) : super(colors: colors);

  @override
  ui.Shader createShader(Rect rect, {TextDirection? textDirection}) {
    const angle = 155 * math.pi / 180;
    final vector = Offset(math.sin(angle), -math.cos(angle));
    final length = rect.width * vector.dx.abs() + rect.height * vector.dy.abs();
    final half = vector * (length / 2);
    return ui.Gradient.linear(rect.center - half, rect.center + half, colors);
  }
}
