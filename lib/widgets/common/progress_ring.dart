import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with rounded caps and an optional colour sweep.
///
/// The arc animates from empty on first build and then only when [value]
/// changes, so ancestor rebuilds (like a once-a-minute clock tick) do not
/// replay it. The animation is skipped when the platform asks to reduce
/// motion.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.trackColor,
    required this.color,
    this.endColor,
    this.size = 84,
    this.strokeWidth = 8,
    this.child,
  });

  /// Progress from 0 to 1.
  final double value;
  final Color trackColor;
  final Color color;

  /// When set, the arc sweeps from [color] to this colour.
  final Color? endColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double target = value.clamp(0.0, 1.0).toDouble();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, Widget? child) {
        return SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _RingPainter(
              value: animated,
              trackColor: trackColor,
              color: color,
              endColor: endColor,
              strokeWidth: strokeWidth,
            ),
            child: Center(child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.trackColor,
    required this.color,
    required this.endColor,
    required this.strokeWidth,
  });

  final double value;
  final Color trackColor;
  final Color color;
  final Color? endColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Rect arcRect = rect.deflate(strokeWidth / 2);
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    if (value <= 0) return;
    final double sweep = math.pi * 2 * value;
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color;
    if (endColor != null) {
      // The round cap pokes backwards past the start angle; start the sweep
      // that far back so the cap keeps the start colour instead of wrapping
      // around to the end colour.
      final double capAngle = strokeWidth / (size.shortestSide - strokeWidth);
      arc.shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: <Color>[color, endColor!],
        transform: GradientRotation(-math.pi / 2 - capAngle),
      ).createShader(rect);
    }
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) {
    return old.value != value ||
        old.trackColor != trackColor ||
        old.color != color ||
        old.endColor != endColor ||
        old.strokeWidth != strokeWidth;
  }
}
