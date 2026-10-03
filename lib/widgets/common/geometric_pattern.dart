import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A faded lattice of eight-pointed stars (two interlocking squares), drawn
/// with hairline strokes.
///
/// It paints once, ignores pointer events and fades out with distance from
/// [anchor], so it reads as texture on hero surfaces rather than a repeating
/// wallpaper.
class GeometricPattern extends StatelessWidget {
  const GeometricPattern({
    super.key,
    required this.color,
    this.starRadius = 15,
    this.strokeWidth = 0.9,
    this.anchor = AlignmentDirectional.topEnd,
    this.reach = 1.0,
    this.maxOpacity = 0.22,
  });

  /// Stroke colour before the distance fade is applied.
  final Color color;

  /// Half the side of the inner square; the star tips sit at ~1.41x this.
  final double starRadius;
  final double strokeWidth;

  /// Where the pattern is strongest.
  final AlignmentGeometry anchor;

  /// How far the fade travels, as a multiple of the longest side.
  final double reach;
  final double maxOpacity;

  @override
  Widget build(BuildContext context) {
    final Alignment resolved = anchor.resolve(Directionality.of(context));
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _GeometricPatternPainter(
            color: color,
            starRadius: starRadius,
            strokeWidth: strokeWidth,
            anchor: resolved,
            reach: reach,
            maxOpacity: maxOpacity,
          ),
        ),
      ),
    );
  }
}

class _GeometricPatternPainter extends CustomPainter {
  const _GeometricPatternPainter({
    required this.color,
    required this.starRadius,
    required this.strokeWidth,
    required this.anchor,
    required this.reach,
    required this.maxOpacity,
  });

  final Color color;
  final double starRadius;
  final double strokeWidth;
  final Alignment anchor;
  final double reach;
  final double maxOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || starRadius <= 0) return;
    canvas.clipRect(Offset.zero & size);

    final double h = starRadius;
    final double tip = h * math.sqrt2;
    // Neighbouring tips just touch, which makes the stars read as interlocked.
    final double step = tip * 2;
    final Offset anchorPoint = anchor.alongSize(size);
    final double fadeDistance = size.longestSide * reach;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.miter;

    for (double cy = 0; cy <= size.height + step; cy += step) {
      for (double cx = 0; cx <= size.width + step; cx += step) {
        final double distance = (Offset(cx, cy) - anchorPoint).distance;
        final double falloff = (1 - distance / fadeDistance).clamp(0.0, 1.0);
        if (falloff <= 0) continue;
        final double opacity = maxOpacity * falloff * falloff;
        if (opacity < 0.01) continue;
        paint.color = color.withValues(alpha: opacity);
        canvas.drawPath(_star(cx, cy, h, tip), paint);
      }
    }
  }

  static Path _star(double cx, double cy, double h, double tip) {
    return Path()
      ..moveTo(cx - h, cy - h)
      ..lineTo(cx + h, cy - h)
      ..lineTo(cx + h, cy + h)
      ..lineTo(cx - h, cy + h)
      ..close()
      ..moveTo(cx, cy - tip)
      ..lineTo(cx + tip, cy)
      ..lineTo(cx, cy + tip)
      ..lineTo(cx - tip, cy)
      ..close();
  }

  @override
  bool shouldRepaint(_GeometricPatternPainter old) {
    return old.color != color ||
        old.starRadius != starRadius ||
        old.strokeWidth != strokeWidth ||
        old.anchor != anchor ||
        old.reach != reach ||
        old.maxOpacity != maxOpacity;
  }
}

/// A hairline rule with a small eight-pointed star in the middle, used to
/// close off hero surfaces and section headings.
class OrnamentDivider extends StatelessWidget {
  const OrnamentDivider({
    super.key,
    required this.color,
    this.starSize = 10,
    this.gap = 8,
  });

  final Color color;
  final double starSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final Widget line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[color.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
    final Widget mirroredLine = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
    return Row(
      children: <Widget>[
        line,
        SizedBox(width: gap),
        SizedBox.square(
          dimension: starSize,
          child: CustomPaint(painter: _StarPainter(color)),
        ),
        SizedBox(width: gap),
        mirroredLine,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.shortestSide / 2;
    final Offset c = size.center(Offset.zero);
    final Path path = Path();
    for (int i = 0; i < 16; i++) {
      final double radius = i.isEven ? r : r * 0.62;
      final double angle = -math.pi / 2 + i * math.pi / 8;
      final Offset p = c + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
