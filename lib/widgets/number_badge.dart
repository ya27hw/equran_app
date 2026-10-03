import 'dart:math' as math;

import 'package:equran/theme/equran_colors.dart';
import 'package:flutter/material.dart';

class SurahNumberBadge extends StatelessWidget {
  const SurahNumberBadge({
    super.key,
    required this.number,
    this.size = 44,
    this.textStyle,
    this.active = false,
  });

  final int number;
  final double size;
  final TextStyle? textStyle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return _DiamondNumberBadge(
      label: number.toString(),
      size: size,
      textStyle: textStyle,
      active: active,
    );
  }
}

class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.label, this.size = 44});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _DiamondNumberBadge(label: label, size: size);
  }
}

class _DiamondNumberBadge extends StatelessWidget {
  const _DiamondNumberBadge({
    required this.label,
    required this.size,
    this.textStyle,
    this.active = false,
  });

  final String label;
  final double size;
  final TextStyle? textStyle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EquranColors colors = context.equranColors;
    final double fontSize = label.length >= 3
        ? (size * 0.29).clamp(10.8, 12.4).toDouble()
        : (size * 0.36).clamp(13.0, 15.5).toDouble();

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _StarBadgePainter(
          stroke: colors.accentGold,
          fill: colors.accentGold.withValues(alpha: active ? 0.22 : 0.08),
          strokeWidth: active ? 1.4 : 1.1,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: size * 0.5,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                strutStyle: StrutStyle(
                  fontSize: fontSize,
                  height: 1,
                  forceStrutHeight: true,
                ),
                style: theme.textTheme.labelLarge
                    ?.copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: colors.textPrimary,
                    )
                    .merge(textStyle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Eight-pointed star (two interlocking squares), the classic Rub el Hizb
/// marker, drawn with a gold hairline and a faint fill.
class _StarBadgePainter extends CustomPainter {
  const _StarBadgePainter({
    required this.stroke,
    required this.fill,
    required this.strokeWidth,
  });

  final Color stroke;
  final Color fill;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide * 0.47 - strokeWidth;
    final Path path = Path();
    for (int i = 0; i < 16; i++) {
      // Alternate between the star tips and the notches between them.
      final double radius = i.isEven ? r : r * 0.76;
      final double angle = -math.pi / 2 + i * math.pi / 8;
      final Offset p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(_StarBadgePainter old) {
    return old.stroke != stroke ||
        old.fill != fill ||
        old.strokeWidth != strokeWidth;
  }
}
